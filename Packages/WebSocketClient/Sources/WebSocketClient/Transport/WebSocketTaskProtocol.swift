//
//  WebSocketTaskProtocol.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// One physical WebSocket connection.
///
/// Abstracts `URLSessionWebSocketTask` so the client's reconnect and heartbeat logic can be tested
/// without a server.
///
/// - Warning: `cancel()` must make every pending `receive()`, `send(_:)` and `sendPing()` throw.
///   The client relies on it to tear down a connection whose operations are suspended.
public protocol WebSocketTaskProtocol: Sendable {

    /// The HTTP status of the upgrade response, once one has been received.
    var httpStatusCode: Int? { get }

    /// The upgrade response's `Retry-After` (e.g. with 429 or 503), or `nil` when absent.
    var retryAfter: Duration? { get }

    /// The close code from the server's close frame (e.g. an application code like `4401`), or `nil` when
    /// the connection has not been closed with one.
    var closeCode: Int? { get }

    /// The close frame's reason as UTF-8 text, or `nil` when absent.
    var closeReason: String? { get }

    /// Starts the handshake.
    func resume()

    /// Closes the connection with a normal-closure code and fails all pending operations.
    func cancel()

    /// Sends one frame.
    func send(_ message: WebSocketMessage) async throws

    /// Waits for the next frame.
    func receive() async throws -> WebSocketMessage

    /// Sends a ping and returns when the matching pong arrives.
    func sendPing() async throws
}
