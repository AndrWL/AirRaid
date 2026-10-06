//
//  DIAppContaining.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// The root DI container that holds all sub-containers.
///
/// `DIAppContaining` is the single entry point for accessing dependencies across the app.
/// It does **not** register or resolve dependencies itself — it delegates to sub-containers.
///
/// ## Lifecycle
///
/// 1. Create `DIAppContainer` at app launch.
/// 2. Call `setup()` once — this triggers `assemble(with:)` on all sub-containers.
/// 3. Pass `DIAppContaining` (or individual sub-containers) to modules that need dependencies.
///
/// ```swift
/// // In AppConfigurator or AirRaid.swift
/// let appContainer = DIAppContainer()
/// appContainer.setup()
///
/// // Pass only what the module needs
/// let viewModel = ProfileViewModel(repositories: appContainer.repositories)
/// ```
///
/// ## Adding a new sub-container
///
/// 1. Create a protocol (e.g., `DIStorageContaining`) with resolved dependency properties.
/// 2. Create a class (e.g., `DIStorageContainer`) conforming to both the protocol and `DIAssembling`.
/// 3. Add a property to this protocol: `var storage: DIStorageContaining { get }`.
/// 4. Add the container to `DIAppContainer` and call `assemble(with:)` in `setup()`.
protocol DIAppContaining {
    
    /// Provides access to the application's service-layer dependencies (e.g., network, auth, analytics).
    var services: DIServiceContaining { get }
    
    /// Provides access to the application's repository-layer dependencies (e.g., local storage, remote data fetchers).
    var repositories: DIRepositoryContaining { get }
    
    /// Provides access to the application's routing dependencies for navigating between screens or flows.
    var routers: DIRouterContaining { get }
    
    /// Initializes and wires up all the dependencies across all sub-containers.
    ///
    /// This method must be called exactly once during the application launch sequence,
    /// typically in the `AppDelegate` or App entry point, before any dependencies are accessed.
    func setup()
}
