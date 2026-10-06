//
//  DIRepositoryContainer.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

import DependencyContainer

/// DI container for repository-layer dependencies.
///
/// Uses its own `DefaultDependencyContainer` instance internally.
/// Dependencies are registered in `assemble(with:)` and exposed through `DIRepositoryContaining` properties.
///
/// ## Registering a new repository
///
/// Repositories typically depend on services. Use `appContainer.services` to access them:
///
/// ```swift
/// func assemble(with appContainer: DIAppContaining) {
///     let services = appContainer.services
///
///     container.register(UserRepositoryProtocol.self, lifetime: .transient) { _ in
///         UserRepositoryImpl(networkClient: services.networkClient)
///     }
/// }
/// ```
///
/// Then expose it:
/// ```swift
/// var userRepository: UserRepositoryProtocol {
///     container.resolve(UserRepositoryProtocol.self)
/// }
/// ```
///
/// ## Lifetime guidelines
///
/// - `.transient` — most repositories (stateless, depend on shared singleton services).
/// - `.singleton` — only if the repository maintains its own cache or state.
final class DIRepositoryContainer {
    
    /// The underlying container that handles the actual registration and resolution of dependencies.
    private let container: DependencyContaining
    
    /// Initializes a new service dependency container.
    ///
    /// - Parameter container: The core container instance to use for dependency management.
    ///   Defaults to a new instance of ``DefaultDependencyContainer``.
    init(
        container: DependencyContaining = DefaultDependencyContainer()
    ) {
        self.container = container
    }
}

// MARK: - DIAssembling

extension DIRepositoryContainer: DIAssembling {

    func assemble(with appContainer: DIAppContaining) {
        
    }
}

// MARK: - DIRepositoryContaining

extension DIRepositoryContainer: DIRepositoryContaining {

}

// MARK: - Configuration

private extension DIRepositoryContainer {
    
    /* Usage exemple
    func registerUserRepository(with appContainer: DIAppContaining) {
        container.register(UserRepositoryProtocol.self, lifetime: .transient) { _ in
            UserRepository(
                remoteDataSource: UserRemoteDataSource(
                    httpClient: <#T##any HTTPClient#>,
                    requestFactory: <#T##any UserRequestFactoryProtocol#>,
                    jsonDecoder: <#T##JSONDecoder#>
                ),
                storageProvider: appContainer.services.storageProvider
            )
        }
    }
     */
}
