//
//  SingletonProvider.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// A provider that creates the dependency once and caches it for all subsequent resolves.
///
/// The instance is created lazily on the first call to `provide(using:)`.
/// Isolated to the `MainActor`, so no internal synchronization is needed.
@MainActor
final class SingletonProvider {
    
    /// The closure responsible for creating the dependency instance.
    private let factory: @MainActor (DependencyResolving) -> Any
    
    /// The cached instance of the dependency, stored after the initial creation.
    private var cachedInstance: Any?
    
    /// Initializes a new singleton provider.
    ///
    /// - Parameter factory: A `MainActor`-isolated closure used to instantiate the dependency.
    init(factory: @escaping @MainActor (DependencyResolving) -> Any) {
        self.factory = factory
    }
}

// MARK: - DependencyProvider

extension SingletonProvider: DependencyProvider {
    
    /// Provides the dependency instance, creating and caching it on the first call.
    ///
    /// If the instance has already been created, this method returns the cached instance immediately.
    /// Otherwise, it uses the factory to create the instance, stores it in `cachedInstance`, and then returns it.
    ///
    /// - Parameter resolver: The resolver used to satisfy any nested dependencies required by the factory.
    /// - Returns: The cached or newly created dependency instance.
    func provide(using resolver: DependencyResolving) -> Any {
        if let cachedInstance {
            return cachedInstance
        }
        
        let instance = factory(resolver)
        cachedInstance = instance
        return instance
    }
}
