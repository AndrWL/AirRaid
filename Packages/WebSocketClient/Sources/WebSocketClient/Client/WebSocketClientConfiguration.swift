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

    /// Supplies the `ws://` or `wss://` endpoint.
    ///
    /// Called before **every** connection attempt, so query items that change between attempts — an API key
    /// passed as `?key=`, a `since` cursor for resuming — are picked up on reconnect.
    /// Throwing counts as a failed attempt and goes through the reconnect policy, unless the error is a
    /// ``WebSocketNonRetryableError``.
    public let urlProvider: @Sendable () async throws -> URL

    /// Supplies HTTP headers for the upgrade request (e.g. `Authorization`).
    ///
    /// Called before **every** connection attempt, so a refreshed token is picked up on reconnect.
    /// Throwing counts as a failed attempt and goes through the reconnect policy.
    public let headersProvider: @Sendable () async throws -> [String: String]

    /// How the handshake is confirmed and liveness is checked.
    public let heartbeat: WebSocketHeartbeat

    /// How often to send a ping on an idle-or-not connection, or `nil` to disable heartbeats.
    public let pingInterval: Duration?

    /// How long to wait for the heartbeat's answer — a pong, or any frame for ``WebSocketHeartbeat/message(_:)`` —
    /// including the one that confirms the handshake, before treating the connection as dead.
    public let pongTimeout: Duration

    /// Timeout for the HTTP upgrade request.
    public let requestTimeout: TimeInterval

    /// Backoff rules for reconnecting after a failure.
    public let reconnectPolicy: ReconnectPolicy

    /// Upgrade-response statuses that stop reconnecting: retrying cannot fix them without new credentials.
    ///
    /// The client reports ``WebSocketClientError/handshakeFailed(statusCode:)`` and ends in `disconnected`;
    /// call `connect()` again once the credentials change.
    public let nonRetryableStatusCodes: Set<Int>

    /// Called with every failure before the client decides whether and when to reconnect.
    ///
    /// Awaited, so it can act on the failure before the next attempt calls ``headersProvider`` — e.g. drop a token
    /// the server rejected with a close code. Events are delivered asynchronously and cannot guarantee that order.
    public let failureHandler: @Sendable (WebSocketClientError) async -> Void

    /// - Parameter urlProvider: Called before every attempt; see ``urlProvider``.
    public init(
        urlProvider: @escaping @Sendable () async throws -> URL,
        headersProvider: @escaping @Sendable () async throws -> [String: String] = { [:] },
        heartbeat: WebSocketHeartbeat = .controlFrame,
        pingInterval: Duration? = .seconds(25),
        pongTimeout: Duration = .seconds(10),
        requestTimeout: TimeInterval = 15,
        reconnectPolicy: ReconnectPolicy = .default,
        nonRetryableStatusCodes: Set<Int> = [401, 403],
        failureHandler: @escaping @Sendable (WebSocketClientError) async -> Void = { _ in }
    ) {
        self.urlProvider = urlProvider
        self.headersProvider = headersProvider
        self.heartbeat = heartbeat
        self.pingInterval = pingInterval
        self.pongTimeout = pongTimeout
        self.requestTimeout = requestTimeout
        self.reconnectPolicy = reconnectPolicy
        self.nonRetryableStatusCodes = nonRetryableStatusCodes
        self.failureHandler = failureHandler
    }

    /// - Parameter url: A fixed endpoint, used for every attempt.
    public init(
        url: URL,
        headersProvider: @escaping @Sendable () async throws -> [String: String] = { [:] },
        heartbeat: WebSocketHeartbeat = .controlFrame,
        pingInterval: Duration? = .seconds(25),
        pongTimeout: Duration = .seconds(10),
        requestTimeout: TimeInterval = 15,
        reconnectPolicy: ReconnectPolicy = .default,
        nonRetryableStatusCodes: Set<Int> = [401, 403],
        failureHandler: @escaping @Sendable (WebSocketClientError) async -> Void = { _ in }
    ) {
        self.init(
            urlProvider: { url },
            headersProvider: headersProvider,
            heartbeat: heartbeat,
            pingInterval: pingInterval,
            pongTimeout: pongTimeout,
            requestTimeout: requestTimeout,
            reconnectPolicy: reconnectPolicy,
            nonRetryableStatusCodes: nonRetryableStatusCodes,
            failureHandler: failureHandler
        )
    }
}
