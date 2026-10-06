//
//  WebSocketMessage.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// A single WebSocket frame payload, independent of the underlying transport.
///
/// Mirrors `URLSessionWebSocketTask.Message` so that consumers and tests never depend on `URLSession` types.
public enum WebSocketMessage: Equatable, Sendable {

    /// A UTF-8 text frame.
    case text(String)

    /// A binary frame.
    case data(Data)
}
