//
//  WebSocketConnectionState.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// The lifecycle state of a ``WebSocketClient`` connection.
public enum WebSocketConnectionState: Equatable, Sendable {

    /// No connection and none requested — the initial state and the state after `disconnect()`
    /// or after reconnect attempts are exhausted.
    case disconnected

    /// A handshake is in progress.
    case connecting

    /// The handshake succeeded and the first pong arrived; messages can be sent.
    case connected

    /// The connection was lost and the client is waiting before the next attempt.
    ///
    /// - Parameters:
    ///   - attempt: The 1-based number of the upcoming reconnect attempt.
    ///   - delay: How long the client waits before that attempt.
    case reconnecting(attempt: Int, delay: Duration)

    /// The device has no network path; the client reconnects as soon as one appears.
    case waitingForNetwork
}
