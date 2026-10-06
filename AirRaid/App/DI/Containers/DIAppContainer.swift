//
//  DIAppContainer.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// The root DI container that manages all sub-containers.
///
/// `DIAppContainer` does not register or resolve dependencies itself.
/// It creates sub-containers and orchestrates their assembly in the correct order.
///
/// ## Setup
///
/// ```swift
/// let appContainer = DIAppContainer()
/// appContainer.setup()
/// ```
///
/// `setup()` calls `assemble(with:)` on each sub-container sequentially.
/// Order matters — containers that other containers depend on must be assembled first.
/// Currently: services → repositories → routers
/// (repositories may depend on services, routers may depend on both).
///
/// ## Adding a new sub-container
///
/// 1. Create `DIStorageContaining` protocol with dependency properties.
/// 2. Create `DIStorageContainer` conforming to `DIStorageContaining` and `DIAssembling`.
/// 3. Add to this class:
///    ```swift
///    private let storageContainer: DIStorageContainer
///    // in init:
///    storageContainer = DIStorageContainer()
///    // in DIAppContaining:
///    var storage: DIStorageContaining { storageContainer }
///    // in setup():
///    storageContainer.assemble(with: self)
///    ```
/// 4. Add `var storage: DIStorageContaining { get }` to `DIAppContaining` protocol.
final class DIAppContainer {

    /// The sub-container responsible for managing service-layer dependencies (e.g., API clients, tracking).
    private let serviceContainer: DIServiceContainer
    
    /// The sub-container responsible for managing repository-layer dependencies (e.g., data mapping, persistence).
    private let repositoryContainer: DIRepositoryContainer
    
    /// The sub-container responsible for managing navigation router dependencies.
    private let routerContainer: DIRouterContainer

    /// Initializes the root application container and instantiates all internal sub-containers.
    init() {
        serviceContainer = DIServiceContainer()
        repositoryContainer = DIRepositoryContainer()
        routerContainer = DIRouterContainer()
    }
}

// MARK: - DIAppContaining

extension DIAppContainer: DIAppContaining {

    var services: DIServiceContaining {
        return serviceContainer
    }

    var repositories: DIRepositoryContaining {
        return repositoryContainer
    }
    
    var routers: DIRouterContaining {
        return routerContainer
    }

    func setup() {
        serviceContainer.assemble(with: self)
        repositoryContainer.assemble(with: self)
        routerContainer.assemble(with: self)
    }
}
