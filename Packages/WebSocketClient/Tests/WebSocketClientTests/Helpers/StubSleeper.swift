//
//  StubSleeper.swift
//  WebSocketClientTests
//

import WebSocketClient

/// Scriptable ``Sleeping``: each call either returns at once or suspends until cancelled.
///
/// Suspending is how a test says "this timer never fires" — e.g. a pong timeout that must lose
/// the race against a pong.
final class StubSleeper: @unchecked Sendable {

    enum Behavior: Sendable {
        case immediate
        case suspend
    }

    /// Decides the behaviour from the requested duration and how many times that duration was requested before.
    typealias Script = @Sendable (_ duration: Duration, _ previousCalls: Int) -> Behavior

    // MARK: - Variables

    private let script: Script

    // Unchecked Sendable: all mutable state is behind `LockIsolated`.
    private let recordedDurations = LockIsolated<[Duration]>([])

    init(
        script: @escaping Script = { _, _ in .immediate }
    ) {
        self.script = script
    }

    var durations: [Duration] { recordedDurations.value }
}

// MARK: - Sleeping

extension StubSleeper: Sleeping {

    func sleep(for duration: Duration) async throws {
        let previousCalls = recordedDurations.withValue { durations in
            defer { durations.append(duration) }
            return durations.filter { $0 == duration }.count
        }

        switch script(duration, previousCalls) {
        case .immediate:
            try Task.checkCancellation()
        case .suspend:
            try await Self.waitForCancellation()
        }
    }
}

// MARK: - Private methods

private extension StubSleeper {

    /// Suspends until the task is cancelled — no timer involved, so the call can never "fire" on its own.
    static func waitForCancellation() async throws {
        let (stream, continuation) = AsyncStream<Never>.makeStream()
        await withTaskCancellationHandler {
            for await _ in stream {}
        } onCancel: {
            continuation.finish()
        }
        throw CancellationError()
    }
}
