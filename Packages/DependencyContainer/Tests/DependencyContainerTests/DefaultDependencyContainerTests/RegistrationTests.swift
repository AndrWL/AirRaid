//
//  RegistrationTests.swift
//  DependencyContainerTests
//

import Testing
@testable import DependencyContainer

/// Tests for basic registration and resolution behavior of ``DefaultDependencyContainer``.
///
/// Covers:
/// - Resolving a previously registered dependency returns the expected instance.
/// - Registering the same type twice overwrites the first registration.
@Suite
struct RegistrationTests {

    // MARK: - Tests

    @Test
    func resolve_whenTypeRegistered_returnsInstance() {
        let sut = makeSUT()
        let id = "test"
        sut.register(ServiceProtocol.self, lifetime: .transient) { _ in
            ServiceImpl(id: id)
        }

        let service = sut.resolve(ServiceProtocol.self)

        #expect(service.id == id)
    }

    @Test
    func register_whenSameTypeRegisteredTwice_overwritesPrevious() {
        let sut = makeSUT()
        sut.register(ServiceProtocol.self, lifetime: .transient) { _ in
            ServiceImpl(id: "first")
        }
        sut.register(ServiceProtocol.self, lifetime: .transient) { _ in
            ServiceImpl(id: "second")
        }

        let service = sut.resolve(ServiceProtocol.self)

        #expect(service.id == "second")
    }
    
    // MARK: - Helpers

    private func makeSUT() -> DefaultDependencyContainer {
        DefaultDependencyContainer()
    }
}
