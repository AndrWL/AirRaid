//
//  LockIsolated.swift
//  DependencyContainerTests
//

import Foundation

/// A thread-safe wrapper for capturing and reading values from `@Sendable` closures in tests.
final class LockIsolated<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: Value) { _value = value }

    /// The current value, read under the lock.
    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    @discardableResult
    func withValue<T>(_ operation: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation(&_value)
    }
}
