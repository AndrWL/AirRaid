//
//  WebSocketClient.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Default ``WebSocketClientProtocol`` implementation.
///
/// ## Connection loop
///
/// ```
/// connect()
///   → connecting → upgrade request (fresh headers) → first ping/pong confirms the handshake → connected
///   → receive loop ∥ heartbeat loop — the first one to fail tears the connection down
///   → failure event → reconnecting(attempt, delay) → backoff sleep → connecting → …
/// ```
///
/// A successful connection resets the attempt counter. Losing the network path stops the loop
/// (`waitingForNetwork`); regaining it starts a fresh loop immediately, without backoff.
///
/// ## Concurrency
///
/// State lives in the actor. Every loop run carries a `generation`; `disconnect()` and network changes
/// bump it, so a cancelled loop that resumes late can never overwrite newer state.
///
/// - Warning: Running loops retain the client. Call ``disconnect()`` to release it.
public actor WebSocketClient {

    // MARK: - Variables

    nonisolated public let events: AsyncStream<WebSocketEvent>

    private let configuration: WebSocketClientConfiguration
    private let taskFactory: WebSocketTaskFactoryProtocol
    private let pathMonitor: NetworkPathMonitoring?
    private let sleeper: Sleeping
    private let randomUnit: @Sendable () -> Double
    private let eventsContinuation: AsyncStream<WebSocketEvent>.Continuation

    private var state: WebSocketConnectionState = .disconnected
    private var isConnectionRequested = false
    private var isNetworkAvailable = true
    private var generation = 0
    private var activeTask: WebSocketTaskProtocol?
    private var connectionLoop: Task<Void, Never>?
    private var pathMonitoringLoop: Task<Void, Never>?

    /// - Parameters:
    ///   - configuration: Endpoint, headers, heartbeat and reconnect settings.
    ///   - taskFactory: Creates the transport for each attempt.
    ///   - pathMonitor: Network availability source, or `nil` to ignore network changes.
    ///   - sleeper: Used for backoff, heartbeat interval, and pong timeout.
    ///   - randomUnit: Source of jitter in `0...1`.
    public init(
        configuration: WebSocketClientConfiguration,
        taskFactory: WebSocketTaskFactoryProtocol = URLSessionWebSocketTaskFactory(),
        pathMonitor: NetworkPathMonitoring? = NWNetworkPathMonitor(),
        sleeper: Sleeping = TaskSleeper(),
        randomUnit: @escaping @Sendable () -> Double = { Double.random(in: 0...1) }
    ) {
        self.configuration = configuration
        self.taskFactory = taskFactory
        self.pathMonitor = pathMonitor
        self.sleeper = sleeper
        self.randomUnit = randomUnit
        (events, eventsContinuation) = AsyncStream.makeStream(bufferingPolicy: .unbounded)
    }

    deinit {
        connectionLoop?.cancel()
        pathMonitoringLoop?.cancel()
        activeTask?.cancel()
        eventsContinuation.finish()
    }
}

// MARK: - WebSocketClientProtocol

extension WebSocketClient: WebSocketClientProtocol {

    public var connectionState: WebSocketConnectionState {
        state
    }

    public func connect() {
        guard !isConnectionRequested else { return }
        isConnectionRequested = true
        startPathMonitoring()
        startConnectionLoop()
    }

    public func disconnect() {
        isConnectionRequested = false
        pathMonitoringLoop?.cancel()
        pathMonitoringLoop = nil
        // The next `connect()` gets a fresh current status from the monitor.
        isNetworkAvailable = true
        stopConnectionLoop()
        updateState(.disconnected)
    }

    public func send(_ message: WebSocketMessage) async throws {
        guard state == .connected, let activeTask else {
            throw WebSocketClientError.notConnected
        }
        try await activeTask.send(message)
    }
}

// MARK: - Private methods

private extension WebSocketClient {

    // MARK: Loop control

    func startConnectionLoop() {
        guard isNetworkAvailable else {
            updateState(.waitingForNetwork)
            return
        }
        generation += 1
        let loopGeneration = generation
        connectionLoop = Task { [weak self] in
            await self?.runConnectionLoop(generation: loopGeneration)
        }
    }

    func stopConnectionLoop() {
        generation += 1
        connectionLoop?.cancel()
        connectionLoop = nil
        // Cancelling the transport is what unblocks a suspended `receive()` / `sendPing()`.
        activeTask?.cancel()
        activeTask = nil
    }

    func isCurrent(_ loopGeneration: Int) -> Bool {
        loopGeneration == generation && !Task.isCancelled
    }

    func startPathMonitoring() {
        guard let pathMonitor, pathMonitoringLoop == nil else { return }
        let updates = pathMonitor.pathUpdates()
        pathMonitoringLoop = Task { [weak self] in
            for await isAvailable in updates {
                await self?.handleNetworkChange(isAvailable: isAvailable)
            }
        }
    }

    func handleNetworkChange(isAvailable: Bool) {
        guard isAvailable != isNetworkAvailable else { return }
        isNetworkAvailable = isAvailable
        guard isConnectionRequested else { return }

        stopConnectionLoop()
        if isAvailable {
            startConnectionLoop()
        } else {
            updateState(.waitingForNetwork)
        }
    }

    // MARK: Connection

    func runConnectionLoop(generation loopGeneration: Int) async {
        var attempt = 0
        while isCurrent(loopGeneration) {
            if attempt > 0 {
                guard await waitBeforeReconnect(attempt: attempt, generation: loopGeneration) else { return }
            }
            updateState(.connecting)

            do {
                try await openConnection(generation: loopGeneration)
            } catch {
                guard isCurrent(loopGeneration) else { return }
                emit(.failure(mapError(error)))
            }

            // A connection that reached `connected` starts backoff from scratch.
            attempt = state == .connected ? 1 : attempt + 1
            activeTask?.cancel()
            activeTask = nil
        }
    }

    /// Sleeps according to the reconnect policy.
    ///
    /// - Returns: `false` if the loop must stop (cancelled, superseded, or attempts exhausted).
    func waitBeforeReconnect(
        attempt: Int,
        generation loopGeneration: Int
    ) async -> Bool {
        let policy = configuration.reconnectPolicy
        if let maxAttempts = policy.maxAttempts, attempt > maxAttempts {
            finishAfterExhaustingAttempts()
            return false
        }

        let delay = policy.delay(forAttempt: attempt, randomUnit: randomUnit())
        updateState(.reconnecting(attempt: attempt, delay: delay))
        do {
            try await sleeper.sleep(for: delay)
        } catch {
            return false
        }
        return isCurrent(loopGeneration)
    }

    func openConnection(generation loopGeneration: Int) async throws {
        let headers = try await configuration.headersProvider()
        guard isCurrent(loopGeneration) else { throw CancellationError() }

        var request = URLRequest(url: configuration.url, timeoutInterval: configuration.requestTimeout)
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let task = taskFactory.makeTask(with: request)
        activeTask = task
        task.resume()

        // `URLSessionWebSocketTask` has no async "opened" signal; the first pong proves the upgrade succeeded.
        try await Self.ping(task, timeout: configuration.pongTimeout, sleeper: sleeper)
        guard isCurrent(loopGeneration) else { throw CancellationError() }
        updateState(.connected)

        try await Self.runConnection(
            task,
            pingInterval: configuration.pingInterval,
            pongTimeout: configuration.pongTimeout,
            sleeper: sleeper,
            events: eventsContinuation
        )
    }

    /// Runs the receive and heartbeat loops until either fails, then cancels the transport so the other unblocks.
    nonisolated static func runConnection(
        _ task: WebSocketTaskProtocol,
        pingInterval: Duration?,
        pongTimeout: Duration,
        sleeper: Sleeping,
        events: AsyncStream<WebSocketEvent>.Continuation
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                while true {
                    events.yield(.message(try await task.receive()))
                }
            }
            if let pingInterval {
                group.addTask {
                    while true {
                        try await sleeper.sleep(for: pingInterval)
                        try await ping(task, timeout: pongTimeout, sleeper: sleeper)
                    }
                }
            }

            do {
                try await group.next()
                task.cancel()
            } catch {
                task.cancel()
                throw await rootCause(of: error, remainingIn: &group)
            }
        }
    }

    /// Picks the error that explains the teardown.
    ///
    /// A pong timeout cancels the transport, which makes `receive()` fail with a generic cancellation error —
    /// possibly before the heartbeat child reports `pongTimeout`. The client's own error is the real cause.
    nonisolated static func rootCause(
        of firstError: Error,
        remainingIn group: inout ThrowingTaskGroup<Void, Error>
    ) async -> Error {
        var cause = firstError
        while let result = await group.nextResult() {
            if !(cause is WebSocketClientError), case .failure(let error as WebSocketClientError) = result {
                cause = error
            }
        }
        return cause
    }

    /// Sends a ping and waits for the pong, failing with ``WebSocketClientError/pongTimeout`` if it is late.
    nonisolated static func ping(
        _ task: WebSocketTaskProtocol,
        timeout: Duration,
        sleeper: Sleeping
    ) async throws {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await task.sendPing()
                return true
            }
            group.addTask {
                try await sleeper.sleep(for: timeout)
                return false
            }
            defer { group.cancelAll() }

            let isPongReceived = try await group.next() ?? false
            if !isPongReceived {
                // Unblocks the pending `sendPing()` so the group can finish.
                task.cancel()
                throw WebSocketClientError.pongTimeout
            }
        }
    }

    func finishAfterExhaustingAttempts() {
        isConnectionRequested = false
        pathMonitoringLoop?.cancel()
        pathMonitoringLoop = nil
        connectionLoop = nil
        emit(.failure(.reconnectAttemptsExhausted))
        updateState(.disconnected)
    }

    // MARK: Events

    func updateState(_ newState: WebSocketConnectionState) {
        guard newState != state else { return }
        state = newState
        emit(.stateChanged(newState))
    }

    func emit(_ event: WebSocketEvent) {
        eventsContinuation.yield(event)
    }

    func mapError(_ error: Error) -> WebSocketClientError {
        if let clientError = error as? WebSocketClientError {
            return clientError
        }
        if let statusCode = activeTask?.httpStatusCode, statusCode != Constants.switchingProtocolsStatusCode {
            return .handshakeFailed(statusCode: statusCode)
        }
        return .transportFailure(error as NSError)
    }
}

// MARK: - Constants

private enum Constants {
    static let switchingProtocolsStatusCode = 101
}
