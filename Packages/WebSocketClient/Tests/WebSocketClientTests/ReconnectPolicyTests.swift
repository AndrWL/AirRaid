//
//  ReconnectPolicyTests.swift
//  WebSocketClientTests
//

import Testing
import WebSocketClient

/// Tests for ``ReconnectPolicy``.
///
/// Covers exponential growth, the max-delay cap, overflow safety, and jitter bounds.
@Suite
struct ReconnectPolicyTests {

    // MARK: - delay(forAttempt:randomUnit:)

    @Test
    func delay_whenFirstAttempt_returnsInitialDelay() {
        let sut = makeSUT()

        let delay = sut.delay(forAttempt: 1, randomUnit: Constants.noJitter)

        #expect(delay == .seconds(1))
    }

    @Test
    func delay_whenAttemptsGrow_multipliesUntilMaxDelay() {
        let sut = makeSUT()

        let delays = (1...7).map { sut.delay(forAttempt: $0, randomUnit: Constants.noJitter) }

        #expect(delays == [.seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(16), .seconds(30), .seconds(30)])
    }

    @Test
    func delay_whenAttemptIsHuge_saturatesAtMaxDelay() {
        let sut = makeSUT()

        let delay = sut.delay(forAttempt: 100_000, randomUnit: Constants.noJitter)

        #expect(delay == .seconds(30))
    }

    @Test
    func delay_whenJitterApplied_staysWithinBounds() {
        let sut = makeSUT(jitter: 0.2)

        let lowest = sut.delay(forAttempt: 2, randomUnit: 0)
        let highest = sut.delay(forAttempt: 2, randomUnit: 1)

        #expect(lowest == .seconds(1.6))
        #expect(highest == .seconds(2.4))
    }

    @Test
    func init_whenJitterOutOfRange_clampsIt() {
        let sut = makeSUT(jitter: 5)

        #expect(sut.jitter == 1)
    }
}

// MARK: - Helpers

private extension ReconnectPolicyTests {

    func makeSUT(
        jitter: Double = 0
    ) -> ReconnectPolicy {
        ReconnectPolicy(
            initialDelay: .seconds(1),
            maxDelay: .seconds(30),
            multiplier: 2,
            jitter: jitter
        )
    }
}

// MARK: - Constants

private enum Constants {
    /// With any jitter, `0.5` maps to a factor of exactly 1.
    static let noJitter = 0.5
}
