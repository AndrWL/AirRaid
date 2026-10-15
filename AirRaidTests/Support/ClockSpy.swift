//
//  ClockSpy.swift
//  AirRaidTests
//

import Foundation

/// A clock the test moves by hand, injected as the code's `now`.
///
/// It also counts its reads, and ``waitForReads(_:)`` returns once the code has read it that many times: a sync point
/// for code that reads the time right before it decides something. An actor that reads the clock and then, without
/// suspending, joins a shared request, is known to have joined it once the read is seen — the actor is not free for
/// anything else until the join suspends.
final class ClockSpy<Instant: Sendable>: @unchecked Sendable {

    private struct Waiter {
        let id: UUID
        let count: Int
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct State {
        var instant: Instant
        var reads = 0
        var waiters: [Waiter] = []
    }

    // MARK: - Variables

    private let state: LockIsolated<State>

    /// How many times the code has read the clock so far.
    var readCount: Int {
        state.value.reads
    }

    init(_ instant: Instant) {
        state = LockIsolated(State(instant: instant))
    }

    // MARK: - Code under test

    /// The current instant; counts as a read.
    func now() -> Instant {
        let (instant, ready) = state.withValue { state -> (Instant, [Waiter]) in
            state.reads += 1
            let reads = state.reads
            let ready = state.waiters.filter { $0.count <= reads }
            state.waiters.removeAll { $0.count <= reads }
            return (state.instant, ready)
        }
        ready.forEach { $0.continuation.resume() }
        return instant
    }

    // MARK: - Test side

    /// Moves the clock; not a read.
    func set(_ instant: Instant) {
        state.withValue { $0.instant = instant }
    }

    /// Returns once the clock has been read `count` times in all.
    func waitForReads(_ count: Int) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let outcome = state.withValue { state -> Result<Void, any Error>? in
                    if Task.isCancelled {
                        return .failure(CancellationError())
                    }
                    if state.reads >= count {
                        return .success(())
                    }
                    state.waiters.append(Waiter(id: id, count: count, continuation: continuation))
                    return nil
                }
                if let outcome {
                    continuation.resume(with: outcome)
                }
            }
        } onCancel: {
            let waiter = state.withValue { state -> Waiter? in
                guard let index = state.waiters.firstIndex(where: { $0.id == id }) else { return nil }
                return state.waiters.remove(at: index)
            }
            waiter?.continuation.resume(throwing: CancellationError())
        }
    }
}
