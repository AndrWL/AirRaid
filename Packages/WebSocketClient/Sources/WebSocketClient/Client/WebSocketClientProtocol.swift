//
//  WebSocketClientProtocol.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// A self-healing WebSocket connection: reconnects with backoff, detects dead connections with pings,
/// and pauses while the device is offline.
public protocol WebSocketClientProtocol: Sendable {

    /// Ordered connection events.
    ///
    /// - Warning: `AsyncStream` supports a **single** consumer. Fan out (e.g. into Combine subjects)
    ///   in the one place that owns the client.
    var events: AsyncStream<WebSocketEvent> { get }

    /// The current connection state.
    var connectionState: WebSocketConnectionState { get async }

    /// Starts connecting and keeps the connection alive until ``disconnect()``. Calling it again while
    /// a connection is requested does nothing.
    func connect() async

    /// Closes the connection and stops reconnecting and network monitoring.
    func disconnect() async

    /// Sends a frame over the live connection.
    ///
    /// - Throws: ``WebSocketClientError/notConnected`` unless the state is `connected`,
    ///   or the transport error if the send itself fails.
    func send(_ message: WebSocketMessage) async throws
}
