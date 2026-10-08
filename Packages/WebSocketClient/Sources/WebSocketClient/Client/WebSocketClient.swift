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
///   → connecting → upgrade request (fresh URL and headers) → heartbeat answer confirms the handshake → connected
///   → receive loop ∥ heartbeat loop — the first one to fail tears the connection down
///   → failure event → reconnecting(attempt, delay) → backoff sleep → connecting → …
/// ```
///
/// A successful connection resets the attempt counter. Losing the network path stops the loop
/// (`waitingForNetwork`); regaining it starts a fresh loop immediately, without backoff.
///
/// The heartbeat (``WebSocketHeartbeat``) is either a ping control frame answered by a pong, or an application
/// message after which any incoming frame counts as the answer; the first frame then also confirms the handshake.
///
/// A rejected upgrade whose status is in ``WebSocketClientConfiguration/nonRetryableStatusCodes``
/// (a bad key) ends the loop in `disconnected`. A `Retry-After` on the upgrade response (rate limiting)
/// lengthens the next backoff delay to at least that long. A ``WebSocketNonRetryableError`` from the URL or headers
/// provider (bad configuration) ends the loop too.
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
        var serverRequestedDelay: Duration?
        while isCurrent(loopGeneration) {
            if attempt > 0 {
                guard await waitBeforeReconnect(
                    attempt: attempt,
                    minimumDelay: serverRequestedDelay,
                    generation: loopGeneration
                ) else { return }
            }
            updateState(.connecting)
            serverRequestedDelay = nil

            do {
                try await openConnection(generation: loopGeneration)
            } catch {
                guard isCurrent(loopGeneration) else { return }
                let failure = mapError(error)
                emit(.failure(failure))
                if error is WebSocketNonRetryableError || isNonRetryable(failure) {
                    finishConnectionLoop()
                    return
                }
                serverRequestedDelay = activeTask?.retryAfter
            }

            // A connection that reached `connected` starts backoff from scratch.
            attempt = state == .connected ? 1 : attempt + 1
            activeTask?.cancel()
            activeTask = nil
        }
    }

    /// Sleeps according to the reconnect policy.
    ///
    /// - Parameters:
    ///   - attempt: The 1-based reconnect attempt number.
    ///   - minimumDelay: The server's `Retry-After`, which wins over a shorter backoff delay.
    ///   - loopGeneration: The generation of the loop that is waiting.
    /// - Returns: `false` if the loop must stop (cancelled, superseded, or attempts exhausted).
    func waitBeforeReconnect(
        attempt: Int,
        minimumDelay: Duration?,
        generation loopGeneration: Int
    ) async -> Bool {
        let policy = configuration.reconnectPolicy
        if let maxAttempts = policy.maxAttempts, attempt > maxAttempts {
            emit(.failure(.reconnectAttemptsExhausted))
            finishConnectionLoop()
            return false
        }

        let backoffDelay = policy.delay(forAttempt: attempt, randomUnit: randomUnit())
        let delay = max(backoffDelay, minimumDelay ?? .zero)
        updateState(.reconnecting(attempt: attempt, delay: delay))
        do {
            try await sleeper.sleep(for: delay)
        } catch {
            return false
        }
        return isCurrent(loopGeneration)
    }

    func openConnection(generation loopGeneration: Int) async throws {
        let url = try await configuration.urlProvider()
        let headers = try await configuration.headersProvider()
        guard isCurrent(loopGeneration) else { throw CancellationError() }

        var request = URLRequest(url: url, timeoutInterval: configuration.requestTimeout)
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let task = taskFactory.makeTask(with: request)
        activeTask = task
        task.resume()

        // `URLSessionWebSocketTask` has no async "opened" signal; the heartbeat's answer proves the upgrade succeeded.
        let firstFrame = try await confirmHandshake(task)
        guard isCurrent(loopGeneration) else { throw CancellationError() }
        updateState(.connected)
        if let firstFrame {
            emit(.message(firstFrame))
        }

        try await Self.runConnection(
            task,
            heartbeat: configuration.heartbeat,
            pingInterval: configuration.pingInterval,
            pongTimeout: configuration.pongTimeout,
            sleeper: sleeper,
            events: eventsContinuation
        )
    }

    /// Waits for the heartbeat's answer.
    ///
    /// - Returns: The first frame when it was the answer — it must still be delivered — or `nil` for a pong.
    func confirmHandshake(_ task: WebSocketTaskProtocol) async throws -> WebSocketMessage? {
        switch configuration.heartbeat {
        case .controlFrame:
            try await Self.ping(task, timeout: configuration.pongTimeout, sleeper: sleeper)
            return nil
        case .message(let ping):
            try await task.send(ping)
            return try await Self.receive(task, timeout: configuration.pongTimeout, sleeper: sleeper)
        }
    }

    /// Runs the receive and heartbeat loops until either fails, then cancels the transport so the other unblocks.
    nonisolated static func runConnection(
        _ task: WebSocketTaskProtocol,
        heartbeat: WebSocketHeartbeat,
        pingInterval: Duration?,
        pongTimeout: Duration,
        sleeper: Sleeping,
        events: AsyncStream<WebSocketEvent>.Continuation
    ) async throws {
        let receivedFrames = FrameCounter()
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                while true {
                    let message = try await task.receive()
                    receivedFrames.increment()
                    events.yield(.message(message))
                }
            }
            if let pingInterval {
                group.addTask {
                    while true {
                        try await sleeper.sleep(for: pingInterval)
                        switch heartbeat {
                        case .controlFrame:
                            try await ping(task, timeout: pongTimeout, sleeper: sleeper)
                        case .message(let ping):
                            let countBeforePing = receivedFrames.count
                            try await task.send(ping)
                            try await sleeper.sleep(for: pongTimeout)
                            if receivedFrames.count == countBeforePing {
                                task.cancel()
                                throw WebSocketClientError.pongTimeout
                            }
                        }
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

    /// Ends the loop from inside it, as if `disconnect()` had been called, without cancelling the running task.
    /// Waits for the next frame, failing with ``WebSocketClientError/pongTimeout`` if none arrives in time.
    nonisolated static func receive(
        _ task: WebSocketTaskProtocol,
        timeout: Duration,
        sleeper: Sleeping
    ) async throws -> WebSocketMessage {
        try await withThrowingTaskGroup(of: WebSocketMessage?.self) { group in
            group.addTask {
                try await task.receive()
            }
            group.addTask {
                try await sleeper.sleep(for: timeout)
                return nil
            }
            defer { group.cancelAll() }

            guard let message = try await group.next() ?? nil else {
                // Unblocks the pending `receive()` so the group can finish.
                task.cancel()
                throw WebSocketClientError.pongTimeout
            }
            return message
        }
    }

    func finishConnectionLoop() {
        isConnectionRequested = false
        pathMonitoringLoop?.cancel()
        pathMonitoringLoop = nil
        connectionLoop = nil
        activeTask?.cancel()
        activeTask = nil
        updateState(.disconnected)
    }

    func isNonRetryable(_ failure: WebSocketClientError) -> Bool {
        guard case .handshakeFailed(let statusCode) = failure else { return false }
        return configuration.nonRetryableStatusCodes.contains(statusCode)
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
