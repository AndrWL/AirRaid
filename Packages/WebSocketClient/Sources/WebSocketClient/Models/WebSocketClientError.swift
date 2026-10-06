//
//  WebSocketClientError.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Errors thrown by ``WebSocketClient/send(_:)`` and reported through ``WebSocketEvent/failure(_:)``.
public enum WebSocketClientError: Error, Equatable, Sendable {

    /// `send(_:)` was called while the client was not in the `connected` state.
    case notConnected

    /// The server rejected the upgrade request with a non-101 HTTP status (e.g. 401 for a bad token).
    case handshakeFailed(statusCode: Int)

    /// No pong arrived within ``WebSocketClientConfiguration/pongTimeout`` — the connection is considered dead.
    case pongTimeout

    /// The transport delivered a frame type this client does not understand.
    case unsupportedMessage

    /// The configured ``ReconnectPolicy/maxAttempts`` were used up; the client is now `disconnected`.
    case reconnectAttemptsExhausted

    /// Any other transport-level error (DNS, TLS, connection reset, close frame, …).
    case transportFailure(NSError)
}
