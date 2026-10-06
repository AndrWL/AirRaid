//
//  DefaultDependencyContainer.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 20.04.2026.
//

import Foundation

/// A thread-safe dependency container that manages registration and resolution of dependencies.
///
/// `DefaultDependencyContainer` is the default implementation of `DependencyContaining`.
/// It uses `NSRecursiveLock` to ensure thread safety, supporting recursive resolution
/// where one dependency's factory resolves another dependency during creation.
///
/// ## Usage
///
/// ```swift
/// let container = DefaultDependencyContainer()
///
/// container.register(NetworkClientProtocol.self, lifetime: .singleton) { _ in
///     NetworkClientImpl()
/// }
///
/// container.register(UserRepositoryProtocol.self, lifetime: .transient) { resolver in
///     UserRepositoryImpl(networkClient: resolver.resolve(NetworkClientProtocol.self))
/// }
///
/// let repository = container.resolve(UserRepositoryProtocol.self)
/// ```
///
/// - Note: Marked as `@unchecked Sendable` because thread safety is guaranteed
///   manually via `NSRecursiveLock`.
public final class DefaultDependencyContainer: @unchecked Sendable, DependencyContaining {
    
    /// A dictionary storing the registered dependency providers, keyed by the `ObjectIdentifier` of the type.
    private var providers: [DependencyKey: DependencyProvider] = [:]
    
    /// A recursive lock used to ensure thread safety during concurrent registration and resolution.
    private let lock = NSRecursiveLock()
    
    /// Initializes a new, empty dependency container.
    public init() {}
    
    // MARK: - Private methods
    
    /// Creates a provider for the given lifetime strategy.
    private func dependencyProvider(
        lifetime: DependencyLifetime,
        factory: @escaping @Sendable (DependencyResolving) -> Any
    ) -> DependencyProvider {
        switch lifetime {
        case .singleton:
            return SingletonProvider(factory: factory)
        case .transient:
            return TransientProvider(factory: factory)
        case .weak:
            return WeakProvider(factory: factory)
        }
    }
}

// MARK: - DependencyResolving

extension DefaultDependencyContainer: DependencyResolving {
    
    /// Resolves and returns a registered dependency of the specified type.
    ///
    /// This method is thread-safe and supports recursive resolution (resolving dependencies
    /// within a dependency factory).
    ///
    /// - Parameters:
    ///   - type: The type of the dependency to resolve.
    ///   - name: An optional string identifier to resolve a specific named registration. Defaults to `nil`.
    /// - Returns: An instance of the requested type `T`.
    /// - Warning: Triggers a `fatalError` if the type (and name) is not registered, or if the registered factory
    ///   returns an incompatible type.
    public func resolve<T>(_ type: T.Type, name: String?) -> T {
        lock.lock()
        defer { lock.unlock() }
        
        let key = DependencyKey(type: ObjectIdentifier(type), name: name)
        
        guard let provider = providers[key] else {
            fatalError("[\(Self.self)] '\(type)' is not registered. Make sure to call register(_:lifetime:factory:) before resolving.")
        }
        
        guard let instance = provider.provide(using: self) as? T else {
            fatalError("[\(Self.self)] Provider for '\(type)' returned incompatible type.")
        }
        
        return instance
    }
}

// MARK: - DependencyRegistering

extension DefaultDependencyContainer: DependencyRegistering {
    
    /// Registers a dependency factory for the specified type.
    ///
    /// This method is thread-safe and allows overriding existing registrations for the same type and name.
    ///
    /// - Parameters:
    ///   - type: The type of the dependency to register.
    ///   - name: An optional string identifier used to distinguish multiple dependencies of the exact same type.
    ///   - lifetime: The strategy determining how instances are created and shared (e.g., `.singleton`, `.transient`, or `.weak`).
    ///   - factory: A thread-safe closure that creates the instance. It is passed a `DependencyResolving`
    ///     instance to allow resolving nested dependencies.
    public func register<T>(
        _ type: T.Type,
        name: String?,
        lifetime: DependencyLifetime,
        factory: @escaping @Sendable (DependencyResolving) -> T
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = DependencyKey(type: ObjectIdentifier(type), name: name)
        let provider = dependencyProvider(lifetime: lifetime, factory: factory)
        providers[key] = provider
    }
}
