//
//  TransientLifetimeTests.swift
//  DependencyContainerTests
//

import Testing
@testable import DependencyContainer

/// Tests for the `.transient` lifetime strategy.
///
/// Covers:
/// - Resolving a transient multiple times returns a new instance each time (`!==`).
/// - The factory is called on every resolve.
@Suite
struct TransientLifetimeTests {

    // MARK: - Tests

    @Test
    func resolve_whenTransient_returnsNewInstance() {
        let sut = makeSUT()
        sut.register(ServiceProtocol.self, lifetime: .transient) { _ in
            ServiceImpl()
        }

        let first = sut.resolve(ServiceProtocol.self)
        let second = sut.resolve(ServiceProtocol.self)

        #expect(first !== second)
    }

    @Test
    func resolve_whenTransient_callsFactoryEveryTime() {
        let sut = makeSUT()
        let factoryCallCount = LockIsolated(0)

        sut.register(ServiceProtocol.self, lifetime: .transient) { _ in
            factoryCallCount.withValue { $0 += 1 }
            return ServiceImpl()
        }

        _ = sut.resolve(ServiceProtocol.self)
        _ = sut.resolve(ServiceProtocol.self)
        _ = sut.resolve(ServiceProtocol.self)

        #expect(factoryCallCount.value == 3)
    }
    
    // MARK: - Helpers

    private func makeSUT() -> DefaultDependencyContainer {
        DefaultDependencyContainer()
    }
}
