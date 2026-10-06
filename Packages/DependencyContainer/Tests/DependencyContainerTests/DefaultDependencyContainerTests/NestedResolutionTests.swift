//
//  NestedResolutionTests.swift
//  DependencyContainerTests
//

import Testing
@testable import DependencyContainer

/// Tests for recursive (nested) resolution — factories that resolve other dependencies.
///
/// Covers:
/// - A factory can call `resolver.resolve()` to obtain its own dependencies.
/// - A singleton resolved through multiple transient consumers is the same instance.
@Suite @MainActor
struct NestedResolutionTests {

    // MARK: - Tests

    @Test
    func resolve_whenFactoryUsesResolver_returnsNestedDependency() {
        let sut = makeSUT()
        sut.register(ServiceProtocol.self, lifetime: .singleton) { _ in
            ServiceImpl(id: "injected")
        }
        sut.register(RepositoryProtocol.self, lifetime: .transient) { resolver in
            RepositoryImpl(service: resolver.resolve(ServiceProtocol.self))
        }

        let repository = sut.resolve(RepositoryProtocol.self)

        #expect(repository.service.id == "injected")
    }

    @Test
    func resolve_whenNestedSingleton_sharedAcrossConsumers() {
        let sut = makeSUT()
        sut.register(ServiceProtocol.self, lifetime: .singleton) { _ in
            ServiceImpl()
        }
        sut.register(RepositoryProtocol.self, lifetime: .transient) { resolver in
            RepositoryImpl(service: resolver.resolve(ServiceProtocol.self))
        }

        let repo1 = sut.resolve(RepositoryProtocol.self)
        let repo2 = sut.resolve(RepositoryProtocol.self)

        #expect(repo1.service === repo2.service)
    }
    
    // MARK: - Helpers

    private func makeSUT() -> DefaultDependencyContainer {
        DefaultDependencyContainer()
    }
}
