//
//  DependencyProvider.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// An internal protocol for objects that provide dependency instances.
///
/// Each implementation defines its own strategy for instance creation and caching.
/// Providers are `MainActor`-isolated and only accessed through the container.
@MainActor
protocol DependencyProvider {

    /// Creates or returns a cached instance of the dependency.
    ///
    /// - Parameter resolver: The resolver used to obtain other dependencies required by the factory.
    /// - Returns: The dependency instance as `Any`. The container is responsible for casting to the expected type.
    func provide(using resolver: DependencyResolving) -> Any
}
