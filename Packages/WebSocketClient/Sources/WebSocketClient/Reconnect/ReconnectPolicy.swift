//
//  ReconnectPolicy.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Exponential backoff with jitter for reconnect attempts.
///
/// Jitter spreads reconnects of many clients after a server restart, so they do not all hit the
/// backend in the same second.
public struct ReconnectPolicy: Equatable, Sendable {

    // MARK: - Variables

    /// Delay before the first reconnect attempt.
    public let initialDelay: Duration

    /// Upper bound for the delay before jitter is applied.
    public let maxDelay: Duration

    /// Factor applied to the delay after every failed attempt.
    public let multiplier: Double

    /// Relative jitter in `0...1`; `0.2` means the delay varies by ±20 %.
    public let jitter: Double

    /// Maximum number of consecutive reconnect attempts, or `nil` to retry forever.
    /// `0` disables reconnecting.
    public let maxAttempts: Int?

    /// Retries forever: 1 s, 2 s, 4 s … capped at 30 s, ±20 % jitter.
    public static let `default` = ReconnectPolicy()

    /// Never reconnects — a dropped connection ends in `disconnected`.
    public static let never = ReconnectPolicy(maxAttempts: 0)

    public init(
        initialDelay: Duration = .seconds(1),
        maxDelay: Duration = .seconds(30),
        multiplier: Double = 2,
        jitter: Double = 0.2,
        maxAttempts: Int? = nil
    ) {
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.multiplier = max(multiplier, 1)
        self.jitter = min(max(jitter, 0), 1)
        self.maxAttempts = maxAttempts
    }

    // MARK: - Methods

    /// Returns the delay before the given reconnect attempt.
    ///
    /// - Parameters:
    ///   - attempt: The 1-based reconnect attempt number.
    ///   - randomUnit: A value in `0...1` used for jitter; injected so the result is deterministic in tests.
    /// - Returns: The delay, never negative.
    public func delay(
        forAttempt attempt: Int,
        randomUnit: Double
    ) -> Duration {
        let exponent = Double(max(attempt - 1, 0))
        // Computed in seconds so a large exponent saturates to `maxDelay` instead of overflowing `Duration`.
        let baseSeconds = min(initialDelay.seconds * pow(multiplier, exponent), maxDelay.seconds)
        let jitterFactor = 1 + jitter * (2 * min(max(randomUnit, 0), 1) - 1)
        return .seconds(max(baseSeconds * jitterFactor, 0))
    }
}

// MARK: - Private methods

private extension Duration {

    /// The duration as fractional seconds.
    var seconds: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
