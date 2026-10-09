//
//  StubWebSocketTask.swift
//  WebSocketClientTests
//

import WebSocketClient

/// In-memory ``WebSocketTaskProtocol``.
///
/// `receive()` suspends until a message is delivered or the task is cancelled, like a real socket.
/// Ping responses are scripted in order; once the script runs out every ping gets a pong.
final class StubWebSocketTask: @unchecked Sendable {

    /// How the stub answers one `sendPing()` call.
    enum PingResponse: Sendable {
        case pong
        case failure(Error)
        /// Never answers until the task is cancelled — simulates a dead connection.
        case noResponse
    }

    private struct State {
        var pingResponses: [PingResponse]
        var queuedMessages: [WebSocketMessage] = []
        var receiveContinuation: CheckedContinuation<WebSocketMessage, Error>?
        var pingContinuations: [CheckedContinuation<Void, Error>] = []
        var sentMessages: [WebSocketMessage] = []
        var pingCount = 0
        var isResumed = false
        var isCancelled = false
        var isDropped = false
    }

    // MARK: - Variables

    let httpStatusCode: Int?
    let retryAfter: Duration?
    let closeCode: Int?
    let closeReason: String?

    // Unchecked Sendable: all mutable state is behind `LockIsolated`.
    private let state: LockIsolated<State>

    init(
        pingResponses: [PingResponse] = [],
        httpStatusCode: Int? = 101,
        retryAfter: Duration? = nil,
        closeCode: Int? = nil,
        closeReason: String? = nil
    ) {
        self.httpStatusCode = httpStatusCode
        self.retryAfter = retryAfter
        self.closeCode = closeCode
        self.closeReason = closeReason
        self.state = LockIsolated(State(pingResponses: pingResponses))
    }

    // MARK: - Inspection

    var sentMessages: [WebSocketMessage] { state.value.sentMessages }
    var pingCount: Int { state.value.pingCount }
    var isResumed: Bool { state.value.isResumed }
    var isCancelled: Bool { state.value.isCancelled }

    /// Simulates a frame arriving from the server.
    func deliver(_ message: WebSocketMessage) {
        state.withValue { state in
            if let continuation = state.receiveContinuation {
                state.receiveContinuation = nil
                continuation.resume(returning: message)
            } else {
                state.queuedMessages.append(message)
            }
        }
    }

    /// Simulates the server dropping the connection. Sticky: a `receive()` that starts later fails too.
    func dropConnection() {
        state.withValue { state in
            state.isDropped = true
            state.receiveContinuation?.resume(throwing: TestError.connectionReset)
            state.receiveContinuation = nil
        }
    }
}

// MARK: - WebSocketTaskProtocol

extension StubWebSocketTask: WebSocketTaskProtocol {

    func resume() {
        state.withValue { $0.isResumed = true }
    }

    func cancel() {
        state.withValue { state in
            state.isCancelled = true
            state.receiveContinuation?.resume(throwing: TestError.cancelled)
            state.receiveContinuation = nil
            state.pingContinuations.forEach { $0.resume(throwing: TestError.cancelled) }
            state.pingContinuations.removeAll()
        }
    }

    func send(_ message: WebSocketMessage) async throws {
        let isAccepted = state.withValue { state in
            guard !state.isCancelled else { return false }
            state.sentMessages.append(message)
            return true
        }
        guard isAccepted else { throw TestError.cancelled }
    }

    func receive() async throws -> WebSocketMessage {
        try await withCheckedThrowingContinuation { continuation in
            state.withValue { state in
                if state.isCancelled {
                    continuation.resume(throwing: TestError.cancelled)
                } else if state.isDropped {
                    continuation.resume(throwing: TestError.connectionReset)
                } else if state.queuedMessages.isEmpty {
                    state.receiveContinuation = continuation
                } else {
                    continuation.resume(returning: state.queuedMessages.removeFirst())
                }
            }
        }
    }

    func sendPing() async throws {
        let response = state.withValue { state -> PingResponse in
            state.pingCount += 1
            return state.pingResponses.isEmpty ? .pong : state.pingResponses.removeFirst()
        }

        switch response {
        case .pong:
            guard !isCancelled else { throw TestError.cancelled }
        case .failure(let error):
            throw error
        case .noResponse:
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                state.withValue { state in
                    if state.isCancelled {
                        continuation.resume(throwing: TestError.cancelled)
                    } else {
                        state.pingContinuations.append(continuation)
                    }
                }
            }
        }
    }
}
