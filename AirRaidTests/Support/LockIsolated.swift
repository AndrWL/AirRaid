//
//  LockIsolated.swift
//  AirRaidTests
//

import Foundation

/// A thread-safe box for state that test doubles share across concurrency domains.
final class LockIsolated<Value>: @unchecked Sendable {

    // MARK: - Variables

    private var storedValue: Value
    private let lock = NSLock()

    init(_ value: Value) {
        storedValue = value
    }

    /// The current value, read under the lock.
    var value: Value {
        lock.withLock { storedValue }
    }

    // MARK: - Methods

    @discardableResult
    func withValue<T>(_ operation: (inout Value) -> T) -> T {
        lock.withLock { operation(&storedValue) }
    }
}
