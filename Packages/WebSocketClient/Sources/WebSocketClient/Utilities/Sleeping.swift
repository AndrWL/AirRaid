//
//  Sleeping.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// Suspends the current task; injected so backoff, heartbeat, and pong timeouts are testable without real waiting.
public protocol Sleeping: Sendable {

    /// Suspends for the given duration.
    ///
    /// - Throws: `CancellationError` if the task is cancelled while sleeping.
    func sleep(for duration: Duration) async throws
}
