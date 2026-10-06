//
//  DIRepositoryContaining.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// Public API for resolving repository-layer dependencies.
///
/// Consumers (ViewModels, UseCases) depend on this protocol — not on `DIRepositoryContainer` directly.
/// This ensures that `assemble(with:)` is hidden and only resolved dependencies are accessible.
///
/// ## Adding a new repository dependency
///
/// 1. Register the dependency in `DIRepositoryContainer.assemble(with:)`:
///    ```swift
///    func assemble(with appContainer: DIAppContaining) {
///        let services = appContainer.services
///        container.register(UserRepositoryProtocol.self, lifetime: .transient) { _ in
///            UserRepositoryImpl(networkClient: services.networkClient)
///        }
///    }
///    ```
/// 2. Expose it as a computed property in this protocol:
///    ```swift
///    protocol DIRepositoryContaining {
///        var userRepository: UserRepositoryProtocol { get }
///    }
///    ```
/// 3. Implement the property in `DIRepositoryContainer`:
///    ```swift
///    var userRepository: UserRepositoryProtocol {
///        container.resolve(UserRepositoryProtocol.self)
///    }
///    ```
///
/// - Note: Repositories typically depend on services. Use `appContainer.services` in `assemble(with:)`
///   to access service-layer dependencies.
protocol DIRepositoryContaining {

}
