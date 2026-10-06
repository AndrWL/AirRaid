//
//  DependencyContaining.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 20.04.2026.
//

/// A protocol for resolving registered dependencies.
///
/// Conforming types provide thread-safe access to previously registered dependencies.
/// This protocol is `Sendable`, allowing the resolver to be safely shared across concurrency domains.
///
/// Use this protocol when a component only needs to **consume** dependencies, not register them.
public protocol DependencyResolving: Sendable {
    
    /// Resolves a dependency of the specified type.
    ///
    /// - Parameters:
    ///   - type: The type to resolve.
    ///   - name: An optional string identifier to resolve a specific named registration.
    /// - Returns: An instance of the requested type.
    /// - Note: Triggers a `fatalError` if the dependency has not been registered.
    func resolve<T>(_ type: T.Type, name: String?) -> T
}

/// A protocol for registering dependencies in the container.
///
/// Conforming types allow callers to bind a type to a factory closure,
/// specifying how and when instances should be created.
///
/// Use this protocol when a component only needs to **register** dependencies (e.g., during app setup).
public protocol DependencyRegistering {
    
    /// Registers a dependency with the specified lifetime.
    ///
    /// - Parameters:
    ///   - type: The type to register.
    ///   - name: An optional string identifier to distinguish between multiple registrations of the same type.
    ///   - lifetime: The lifetime strategy for the dependency (`.singleton`, `.transient`, or `.weak`).
    ///   - factory: A closure that creates an instance of the type.
    ///              Receives a `DependencyResolving` parameter to resolve other nested dependencies.
    func register<T>(_ type: T.Type, name: String?, lifetime: DependencyLifetime, factory: @escaping @Sendable (DependencyResolving) -> T)
}

/// A unified dependency container protocol that supports both registration and resolution.
///
/// Use this protocol when a component needs full access to the container,
/// for example during initial app configuration.
public protocol DependencyContaining: DependencyResolving, DependencyRegistering {}

public extension DependencyRegistering {
    
    /// Registers a dependency with the specified lifetime, without an associated name.
    ///
    /// This is a convenience method that calls the primary `register` method, defaulting the `name` to `nil`.
    /// Use this for standard dependencies where you only need one default instance or factory per type.
    ///
    /// - Parameters:
    ///   - type: The type to register.
    ///   - lifetime: The lifetime strategy for the dependency (e.g., `.singleton`, `.transient`, or `.weak`).
    ///   - factory: A closure that creates an instance of the type.
    ///              Receives a `DependencyResolving` instance to resolve other nested dependencies.
    func register<T>(
        _ type: T.Type,
        lifetime: DependencyLifetime,
        factory: @escaping @Sendable (DependencyResolving) -> T
    ) {
        register(type, name: nil, lifetime: lifetime, factory: factory)
    }
}

public extension DependencyResolving {
    
    /// Resolves a dependency of the specified type without an associated name.
    ///
    /// This is a convenience method that calls the primary `resolve` method, defaulting the `name` to `nil`.
    /// Use this to retrieve the default, unnamed implementation of a registered type.
    ///
    /// - Parameter type: The type to resolve.
    /// - Returns: An instance of the requested type.
    /// - Note: Triggers a `fatalError` if the dependency has not been registered.
    func resolve<T>(_ type: T.Type) -> T {
        resolve(type, name: nil)
    }
}
