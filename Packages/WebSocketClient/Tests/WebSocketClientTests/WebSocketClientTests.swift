//
//  WebSocketClientTests.swift
//  WebSocketClientTests
//

import Foundation
import Testing
import WebSocketClient

/// Tests for ``WebSocketClient``.
///
/// Covers the handshake, message flow, backoff and its reset, non-retryable rejections, `Retry-After`,
/// attempt exhaustion, heartbeat timeouts,
/// network-path changes, and disconnect. Timers run through ``StubSleeper``, so no test waits for real time.
@Suite(.timeLimit(.minutes(1)))
struct WebSocketClientTests {

    // MARK: - connect

    @Test
    func connect_whenHandshakeSucceeds_emitsConnectingThenConnected() async {
        let factory = StubWebSocketTaskFactory()
        let sut = makeSUT(factory: factory)
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)

        #expect(received == [.stateChanged(.connecting), .stateChanged(.connected)])
        #expect(factory.createdTasks.first?.isResumed == true)
        #expect(await sut.connectionState == .connected)
    }

    @Test
    func connect_whenCalledTwice_opensSingleConnection() async {
        let factory = StubWebSocketTaskFactory()
        let sut = makeSUT(factory: factory)
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        #expect(factory.createdTasks.count == 1)
    }

    @Test
    func connect_whenHeadersProvided_addsThemToUpgradeRequest() async {
        let factory = StubWebSocketTaskFactory()
        let sut = makeSUT(
            factory: factory,
            headersProvider: { [Constants.authorizationHeader: Constants.bearerToken] }
        )
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        let request = factory.requests.first
        #expect(request?.url == Constants.url)
        #expect(request?.value(forHTTPHeaderField: Constants.authorizationHeader) == Constants.bearerToken)
    }

    @Test
    func connect_whenReconnecting_asksURLProviderForEveryAttempt() async {
        let urlCalls = LockIsolated(0)
        let failingTask = StubWebSocketTask(pingResponses: [.failure(TestError.connectionReset)])
        let factory = StubWebSocketTaskFactory(tasks: [failingTask])
        let sut = makeSUT(factory: factory, urlProvider: {
            let call = urlCalls.withValue { calls in
                calls += 1
                return calls
            }
            return Constants.url.appending(queryItems: [URLQueryItem(name: "since", value: "\(call)")])
        })
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        #expect(factory.requests.map(\.url?.query) == ["since=1", "since=2"])
    }

    @Test
    func connect_whenURLProviderThrowsNonRetryableError_stopsWithoutRetrying() async {
        let factory = StubWebSocketTaskFactory()
        let sut = makeSUT(factory: factory, urlProvider: { throw StubConfigurationError.missingKey })
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .disconnected)

        #expect(received == [
            .stateChanged(.connecting),
            .failure(.transportFailure(StubConfigurationError.missingKey as NSError)),
            .stateChanged(.disconnected)
        ])
        #expect(factory.createdTasks.isEmpty)
    }

    @Test
    func connect_whenHeadersProviderThrows_reportsFailureAndRetries() async {
        let headersCalls = LockIsolated(0)
        let sut = makeSUT(headersProvider: {
            let call = headersCalls.withValue { calls in
                calls += 1
                return calls
            }
            guard call > 1 else { throw TestError.headersUnavailable }
            return [:]
        })
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)

        #expect(received.contains(.failure(.transportFailure(TestError.headersUnavailable as NSError))))
        #expect(headersCalls.value == 2)
    }

    // MARK: - Messages

    @Test
    func events_whenServerSendsMessage_emitsMessageEvent() async {
        let task = StubWebSocketTask()
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: [task]))
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        task.deliver(.text(Constants.payload))
        let event = await events.next()

        #expect(event == .message(.text(Constants.payload)))
    }

    @Test
    func send_whenConnected_forwardsMessageToTask() async throws {
        let task = StubWebSocketTask()
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: [task]))
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        try await sut.send(.text(Constants.payload))

        #expect(task.sentMessages == [.text(Constants.payload)])
    }

    @Test
    func send_whenNotConnected_throwsNotConnected() async {
        let sut = makeSUT()

        await #expect(throws: WebSocketClientError.notConnected) {
            try await sut.send(.text(Constants.payload))
        }
    }

    // MARK: - Reconnect

    @Test
    func connect_whenHandshakeRejected_reportsStatusCodeAndReconnects() async {
        let rejectedTask = StubWebSocketTask(pingResponses: [.failure(TestError.connectionReset)], httpStatusCode: 500)
        let factory = StubWebSocketTaskFactory(tasks: [rejectedTask])
        let sut = makeSUT(factory: factory)
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)

        #expect(received == [
            .stateChanged(.connecting),
            .failure(.handshakeFailed(statusCode: 500)),
            .stateChanged(.reconnecting(attempt: 1, delay: .seconds(1))),
            .stateChanged(.connecting),
            .stateChanged(.connected)
        ])
        #expect(rejectedTask.isCancelled)
        #expect(factory.createdTasks.count == 2)
    }

    @Test(arguments: [401, 403])
    func connect_whenHandshakeRejectedWithNonRetryableStatus_stopsReconnecting(statusCode: Int) async {
        let rejectedTask = StubWebSocketTask(
            pingResponses: [.failure(TestError.connectionReset)],
            httpStatusCode: statusCode
        )
        let factory = StubWebSocketTaskFactory(tasks: [rejectedTask])
        let sut = makeSUT(factory: factory)
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .disconnected)

        #expect(received == [
            .stateChanged(.connecting),
            .failure(.handshakeFailed(statusCode: statusCode)),
            .stateChanged(.disconnected)
        ])
        #expect(rejectedTask.isCancelled)
        #expect(factory.createdTasks.count == 1)
        #expect(await sut.connectionState == .disconnected)
    }

    @Test
    func connect_afterNonRetryableRejection_connectsAgain() async {
        let rejectedTask = StubWebSocketTask(pingResponses: [.failure(TestError.connectionReset)], httpStatusCode: 401)
        let factory = StubWebSocketTaskFactory(tasks: [rejectedTask])
        let sut = makeSUT(factory: factory)
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .disconnected)

        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        #expect(factory.createdTasks.count == 2)
    }

    @Test
    func connect_whenRateLimitedWithRetryAfter_waitsAtLeastThatLong() async {
        let limitedTask = StubWebSocketTask(
            pingResponses: [.failure(TestError.connectionReset)],
            httpStatusCode: 429,
            retryAfter: .seconds(30)
        )
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: [limitedTask]))
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)

        #expect(received.contains(.failure(.handshakeFailed(statusCode: 429))))
        #expect(reconnectDelays(in: received) == [.seconds(30)])
    }

    @Test
    func connect_whenRetryAfterShorterThanBackoff_usesBackoffDelay() async {
        let failingTask = StubWebSocketTask(pingResponses: [.failure(TestError.connectionReset)])
        let limitedTask = StubWebSocketTask(
            pingResponses: [.failure(TestError.connectionReset)],
            httpStatusCode: 429,
            retryAfter: .seconds(1)
        )
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: [failingTask, limitedTask]))
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)

        #expect(reconnectDelays(in: received) == [.seconds(1), .seconds(2)])
    }

    @Test
    func connect_whenHandshakeKeepsFailing_growsDelayExponentially() async {
        let failingTasks = (1...3).map { _ in StubWebSocketTask(pingResponses: [.failure(TestError.connectionReset)]) }
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: failingTasks))
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)

        #expect(reconnectDelays(in: received) == [.seconds(1), .seconds(2), .seconds(4)])
    }

    @Test
    func connect_whenConnectionDropsAfterSuccess_restartsBackoffFromFirstAttempt() async {
        let failingTask = StubWebSocketTask(pingResponses: [.failure(TestError.connectionReset)])
        let liveTask = StubWebSocketTask()
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: [failingTask, liveTask]))
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        liveTask.dropConnection()
        let received = await collect(&events, untilState: .connected)

        #expect(received.contains(.failure(.transportFailure(TestError.connectionReset as NSError))))
        #expect(reconnectDelays(in: received) == [.seconds(1)])
        #expect(received.contains(.stateChanged(.reconnecting(attempt: 1, delay: .seconds(1)))))
    }

    @Test
    func connect_whenAttemptsExhausted_emitsFailureAndDisconnects() async {
        let failingTasks = (1...2).map { _ in StubWebSocketTask(pingResponses: [.failure(TestError.connectionReset)]) }
        let factory = StubWebSocketTaskFactory(tasks: failingTasks)
        let sut = makeSUT(factory: factory, reconnectPolicy: ReconnectPolicy(jitter: 0, maxAttempts: 1))
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .disconnected)

        #expect(received.suffix(2) == [.failure(.reconnectAttemptsExhausted), .stateChanged(.disconnected)])
        #expect(factory.createdTasks.count == 2)
        #expect(await sut.connectionState == .disconnected)
    }

    // MARK: - Heartbeat

    @Test
    func heartbeat_whenPongMissing_reportsPongTimeoutAndReconnects() async {
        let deadTask = StubWebSocketTask(pingResponses: [.pong, .noResponse])
        let factory = StubWebSocketTaskFactory(tasks: [deadTask])
        // Pong timeout: the handshake one must lose to the pong, the heartbeat one must fire, later ones idle.
        // Ping interval: fire once, then idle so the replacement connection stays quiet.
        let sleeper = StubSleeper { duration, previousCalls in
            switch duration {
            case Constants.pongTimeout:
                return previousCalls == 1 ? .immediate : .suspend
            case Constants.pingInterval:
                return previousCalls == 0 ? .immediate : .suspend
            default:
                return .immediate
            }
        }
        let sut = makeSUT(factory: factory, sleeper: sleeper, pingInterval: Constants.pingInterval)
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        let received = await collect(&events, untilState: .connected)

        #expect(received.first == .failure(.pongTimeout))
        #expect(deadTask.pingCount == 2)
        #expect(deadTask.isCancelled)
        #expect(factory.createdTasks.count == 2)
    }

    // MARK: - Message heartbeat

    @Test
    func connect_whenMessageHeartbeat_sendsPingAndConfirmsHandshakeWithFirstFrame() async {
        let task = StubWebSocketTask()
        task.deliver(.text(Constants.snapshot))
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: [task]), heartbeat: Constants.messageHeartbeat)
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)
        let firstMessage = await events.next()

        #expect(received == [.stateChanged(.connecting), .stateChanged(.connected)])
        #expect(firstMessage == .message(.text(Constants.snapshot)))
        #expect(task.sentMessages == [.text(Constants.pingMessage)])
        #expect(task.pingCount == 0)
    }

    @Test
    func connect_whenMessageHeartbeatGetsNoFrame_reportsPongTimeoutAndReconnects() async {
        let silentTask = StubWebSocketTask()
        let liveTask = StubWebSocketTask()
        liveTask.deliver(.text(Constants.snapshot))
        let factory = StubWebSocketTaskFactory(tasks: [silentTask, liveTask])
        // The first handshake times out; the second one gets its frame first.
        let sleeper = StubSleeper { duration, previousCalls in
            duration == Constants.pongTimeout && previousCalls > 0 ? .suspend : .immediate
        }
        let sut = makeSUT(factory: factory, sleeper: sleeper, heartbeat: Constants.messageHeartbeat)
        var events = sut.events.makeAsyncIterator()

        await sut.connect()
        let received = await collect(&events, untilState: .connected)

        #expect(received.contains(.failure(.pongTimeout)))
        #expect(silentTask.isCancelled)
        #expect(factory.createdTasks.count == 2)
    }

    @Test
    func heartbeat_whenMessageHeartbeatGetsNoFrame_reportsPongTimeoutAndReconnects() async {
        let deadTask = StubWebSocketTask()
        deadTask.deliver(.text(Constants.snapshot))
        let liveTask = StubWebSocketTask()
        liveTask.deliver(.text(Constants.snapshot))
        let factory = StubWebSocketTaskFactory(tasks: [deadTask, liveTask])
        // Pong timeout: the handshake one loses to the queued frame, the heartbeat one fires, later ones idle.
        // Ping interval: fire once, then idle so the replacement connection stays quiet.
        let sleeper = StubSleeper { duration, previousCalls in
            switch duration {
            case Constants.pongTimeout:
                return previousCalls == 1 ? .immediate : .suspend
            case Constants.pingInterval:
                return previousCalls == 0 ? .immediate : .suspend
            default:
                return .immediate
            }
        }
        let sut = makeSUT(
            factory: factory,
            sleeper: sleeper,
            heartbeat: Constants.messageHeartbeat,
            pingInterval: Constants.pingInterval
        )
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        let received = await collect(&events, untilState: .connected)

        #expect(received.contains(.failure(.pongTimeout)))
        #expect(deadTask.sentMessages == [.text(Constants.pingMessage), .text(Constants.pingMessage)])
        #expect(deadTask.isCancelled)
        #expect(factory.createdTasks.count == 2)
    }

    // MARK: - Network path

    @Test
    func connect_whenNetworkLost_waitsAndReconnectsWithoutBackoffWhenRestored() async {
        let monitor = StubNetworkPathMonitor()
        let factory = StubWebSocketTaskFactory()
        let sut = makeSUT(factory: factory, pathMonitor: monitor)
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        monitor.send(false)
        _ = await collect(&events, untilState: .waitingForNetwork)
        monitor.send(true)
        let received = await collect(&events, untilState: .connected)

        #expect(received == [.stateChanged(.connecting), .stateChanged(.connected)])
        #expect(factory.createdTasks.first?.isCancelled == true)
        #expect(factory.createdTasks.count == 2)
    }

    @Test
    func connect_whenStartedOffline_connectsOnceNetworkAppears() async {
        let monitor = StubNetworkPathMonitor()
        let sut = makeSUT(pathMonitor: monitor)
        var events = sut.events.makeAsyncIterator()
        monitor.send(false)

        await sut.connect()
        _ = await collect(&events, untilState: .waitingForNetwork)
        monitor.send(true)
        _ = await collect(&events, untilState: .connected)

        #expect(await sut.connectionState == .connected)
    }

    // MARK: - disconnect

    @Test
    func disconnect_whenConnected_cancelsTaskAndEmitsDisconnected() async {
        let task = StubWebSocketTask()
        let sut = makeSUT(factory: StubWebSocketTaskFactory(tasks: [task]))
        var events = sut.events.makeAsyncIterator()
        await sut.connect()
        _ = await collect(&events, untilState: .connected)

        await sut.disconnect()
        let event = await events.next()

        #expect(event == .stateChanged(.disconnected))
        #expect(task.isCancelled)
        #expect(await sut.connectionState == .disconnected)
    }
}

// MARK: - Helpers

private extension WebSocketClientTests {

    func makeSUT(
        factory: StubWebSocketTaskFactory = StubWebSocketTaskFactory(),
        sleeper: StubSleeper = StubSleeper { duration, _ in duration == Constants.pongTimeout ? .suspend : .immediate },
        pathMonitor: NetworkPathMonitoring? = nil,
        urlProvider: @escaping @Sendable () async throws -> URL = { Constants.url },
        headersProvider: @escaping @Sendable () async throws -> [String: String] = { [:] },
        heartbeat: WebSocketHeartbeat = .controlFrame,
        pingInterval: Duration? = nil,
        reconnectPolicy: ReconnectPolicy = ReconnectPolicy(jitter: 0)
    ) -> WebSocketClient {
        WebSocketClient(
            configuration: WebSocketClientConfiguration(
                urlProvider: urlProvider,
                headersProvider: headersProvider,
                heartbeat: heartbeat,
                pingInterval: pingInterval,
                pongTimeout: Constants.pongTimeout,
                reconnectPolicy: reconnectPolicy
            ),
            taskFactory: factory,
            pathMonitor: pathMonitor,
            sleeper: sleeper,
            randomUnit: { 0.5 }
        )
    }

    /// Reads events until the given state is reached, inclusive.
    func collect(
        _ iterator: inout AsyncStream<WebSocketEvent>.Iterator,
        untilState target: WebSocketConnectionState
    ) async -> [WebSocketEvent] {
        var received: [WebSocketEvent] = []
        while let event = await iterator.next() {
            received.append(event)
            if event == .stateChanged(target) {
                break
            }
        }
        return received
    }

    func reconnectDelays(in events: [WebSocketEvent]) -> [Duration] {
        events.compactMap { event in
            guard case .stateChanged(.reconnecting(_, let delay)) = event else { return nil }
            return delay
        }
    }
}

// MARK: - StubConfigurationError

/// A configuration error the client must not retry.
private enum StubConfigurationError: WebSocketNonRetryableError {
    case missingKey
}

// MARK: - Constants

private enum Constants {
    static let url = URL(string: "wss://example.com/socket") ?? URL(fileURLWithPath: "/")
    static let pongTimeout = Duration.seconds(10)
    static let pingInterval = Duration.seconds(25)
    static let authorizationHeader = "Authorization"
    static let bearerToken = "Bearer test-token"
    static let payload = "payload"
    static let pingMessage = #"{"type":"ping"}"#
    static let snapshot = #"{"type":"snapshot"}"#
    static let messageHeartbeat = WebSocketHeartbeat.message(.text(pingMessage))
}
