//
//  WebSocketHeartbeat.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// How a ``WebSocketClient`` confirms the handshake and checks that a connection is alive.
public enum WebSocketHeartbeat: Equatable, Sendable {

    /// WebSocket ping control frames; the matching pong proves the connection is alive.
    ///
    /// - Warning: `URLSessionWebSocketTask` reads incoming frames only while a `receive()` is pending, so a server
    ///   that sends data right after the upgrade can hold the pong back past the timeout.
    case controlFrame

    /// An application-level message (e.g. `{"type":"ping"}`); **any** frame from the server proves the connection
    /// is alive. The first frame after the upgrade confirms the handshake, so the server must send something on
    /// connect or answer the ping.
    case message(WebSocketMessage)
}
