//
//  WebSocketClientConfiguration.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Immutable settings for a ``WebSocketClient``.
public struct WebSocketClientConfiguration: Sendable {

    // MARK: - Variables

    /// The `ws://` or `wss://` endpoint.
    public let url: URL

    /// Supplies HTTP headers for the upgrade request (e.g. `Authorization`).
    ///
    /// Called before **every** connection attempt, so a refreshed token is picked up on reconnect.
    /// Throwing counts as a failed attempt and goes through the reconnect policy.
    public let headersProvider: @Sendable () async throws -> [String: String]

    /// How often to send a ping on an idle-or-not connection, or `nil` to disable heartbeats.
    public let pingInterval: Duration?

    /// How long to wait for a pong (including the one that confirms the handshake) before
    /// treating the connection as dead.
    public let pongTimeout: Duration

    /// Timeout for the HTTP upgrade request.
    public let requestTimeout: TimeInterval

    /// Backoff rules for reconnecting after a failure.
    public let reconnectPolicy: ReconnectPolicy

    public init(
        url: URL,
        headersProvider: @escaping @Sendable () async throws -> [String: String] = { [:] },
        pingInterval: Duration? = .seconds(25),
        pongTimeout: Duration = .seconds(10),
        requestTimeout: TimeInterval = 15,
        reconnectPolicy: ReconnectPolicy = .default
    ) {
        self.url = url
        self.headersProvider = headersProvider
        self.pingInterval = pingInterval
        self.pongTimeout = pongTimeout
        self.requestTimeout = requestTimeout
        self.reconnectPolicy = reconnectPolicy
    }
}
