//
//  TestTypes.swift
//  DependencyContainerTests
//

/// Shared test doubles used across all ``DefaultDependencyContainer`` test suites.
///
/// - ``ServiceProtocol`` / ``ServiceImpl``: A simple dependency with an `id` for asserting identity.
/// - ``RepositoryProtocol`` / ``RepositoryImpl``: A dependency that depends on ``ServiceProtocol``,
///   used for testing nested resolution.

import Foundation

/// A minimal protocol representing a service dependency.
/// Conforms to `AnyObject` to allow identity checks (`===`) in tests.
protocol ServiceProtocol: AnyObject, Sendable {
    var id: String { get }
}

/// A concrete implementation of ``ServiceProtocol`` for test use.
final class ServiceImpl: ServiceProtocol {
    let id: String

    init(id: String = "default") {
        self.id = id
    }
}

/// A protocol representing a repository that depends on a ``ServiceProtocol``.
protocol RepositoryProtocol {
    var service: ServiceProtocol { get }
}

/// A concrete implementation of ``RepositoryProtocol`` for testing nested resolution.
final class RepositoryImpl: RepositoryProtocol {
    let service: ServiceProtocol

    init(service: ServiceProtocol) {
        self.service = service
    }
}
