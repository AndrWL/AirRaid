//
//  StubNetworkPathMonitor.swift
//  WebSocketClientTests
//

import WebSocketClient

/// ``NetworkPathMonitoring`` driven by the test through ``send(_:)``.
final class StubNetworkPathMonitor: Sendable {

    private let stream: AsyncStream<Bool>
    private let continuation: AsyncStream<Bool>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(bufferingPolicy: .unbounded)
    }

    /// Publishes a new availability value.
    func send(_ isAvailable: Bool) {
        continuation.yield(isAvailable)
    }
}

// MARK: - NetworkPathMonitoring

extension StubNetworkPathMonitor: NetworkPathMonitoring {

    func pathUpdates() -> AsyncStream<Bool> {
        stream
    }
}
