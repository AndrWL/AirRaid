//
//  WebSocketEvent.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// Everything a ``WebSocketClient`` reports to its consumer, in the order it happened.
///
/// A single ordered stream (instead of separate state and message streams) guarantees that a consumer
/// never sees a message before the `connected` state that produced it.
public enum WebSocketEvent: Equatable, Sendable {

    /// The connection state changed. Emitted only on actual changes.
    case stateChanged(WebSocketConnectionState)

    /// A frame arrived from the server.
    case message(WebSocketMessage)

    /// A connection attempt or a live connection failed. The client decides on its own whether to reconnect;
    /// this event exists for logging and for reacting to specific failures such as an expired token.
    case failure(WebSocketClientError)
}
