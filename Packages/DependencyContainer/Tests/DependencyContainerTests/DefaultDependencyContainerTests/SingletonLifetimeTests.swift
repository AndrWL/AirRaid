//
//  SingletonLifetimeTests.swift
//  DependencyContainerTests
//

import Testing
@testable import DependencyContainer

/// Tests for the `.singleton` lifetime strategy.
///
/// Covers:
/// - Resolving a singleton multiple times returns the same instance (`===`).
/// - The factory is called lazily — only on first resolve, not at registration time.
@Suite
struct SingletonLifetimeTests {

    // MARK: - Tests

    @Test
    func resolve_whenSingleton_returnsSameInstance() {
        let sut = makeSUT()
        sut.register(ServiceProtocol.self, lifetime: .singleton) { _ in
            ServiceImpl()
        }

        let first = sut.resolve(ServiceProtocol.self)
        let second = sut.resolve(ServiceProtocol.self)

        #expect(first === second)
    }

    @Test
    func resolve_whenSingleton_createsLazily() {
        let sut = makeSUT()
        let factoryCallCount = LockIsolated(0)

        sut.register(ServiceProtocol.self, lifetime: .singleton) { _ in
            factoryCallCount.withValue { $0 += 1 }
            return ServiceImpl()
        }

        #expect(factoryCallCount.value == 0)

        _ = sut.resolve(ServiceProtocol.self)
        #expect(factoryCallCount.value == 1)

        _ = sut.resolve(ServiceProtocol.self)
        #expect(factoryCallCount.value == 1)
    }
    
    // MARK: - Helpers

    private func makeSUT() -> DefaultDependencyContainer {
        DefaultDependencyContainer()
    }
}
