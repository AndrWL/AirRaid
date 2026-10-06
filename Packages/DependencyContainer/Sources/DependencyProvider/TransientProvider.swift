//
//  TransientProvider.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// A provider that creates a new instance of the dependency on every resolve.
///
/// No caching is performed — each call to `provide(using:)` invokes the factory closure.
struct TransientProvider {
    
    /// The closure responsible for instantiating the dependency.
    private let factory: @Sendable (DependencyResolving) -> Any
    
    /// Initializes a new transient provider.
    ///
    /// - Parameter factory: A `@Sendable` closure used to instantiate a new dependency object.
    init(
        factory: @escaping @Sendable (DependencyResolving) -> Any
    ) {
        self.factory = factory
    }
}

// MARK: - DependencyProvider

extension TransientProvider: DependencyProvider {
    
    /// Creates and returns a new instance of the dependency.
    ///
    /// This method invokes the underlying factory closure every time it is called,
    /// ensuring a fresh instance is provided without any caching.
    ///
    /// - Parameter resolver: The resolver used to satisfy any nested dependencies required by the factory.
    /// - Returns: A newly created dependency instance.
    func provide(using resolver: DependencyResolving) -> Any {
        factory(resolver)
    }
}
