//
//  AsyncQueue.swift
//  AirRaidTests
//

import Foundation

/// Buffers sent elements; ``next()`` suspends until one is available.
///
/// The building block of the spies: the code under test sends a call and waits for a response, the test waits for
/// the call and sends the response — in whichever order, since both sides buffer. Supports one pending ``next()`` at
/// a time; cancelling it throws `CancellationError`, so a test's time limit ends a forgotten wait.
actor AsyncQueue<Element: Sendable> {

    // MARK: - Variables

    private var buffer: [Element] = []
    private var waiter: (id: UUID, continuation: CheckedContinuation<Element, any Error>)?

    // MARK: - Methods

    func send(_ element: Element) {
        if let waiter {
            self.waiter = nil
            waiter.continuation.resume(returning: element)
        } else {
            buffer.append(element)
        }
    }

    func next() async throws -> Element {
        try Task.checkCancellation()
        if !buffer.isEmpty {
            return buffer.removeFirst()
        }
        precondition(waiter == nil, "AsyncQueue supports only one pending next()")
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                waiter = (id, continuation)
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }
}

// MARK: - Private methods

private extension AsyncQueue {

    func cancelWaiter(_ id: UUID) {
        guard let waiter, waiter.id == id else { return }
        self.waiter = nil
        waiter.continuation.resume(throwing: CancellationError())
    }
}
