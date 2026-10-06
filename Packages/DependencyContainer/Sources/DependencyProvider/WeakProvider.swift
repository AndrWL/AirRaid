//
//  WeakProvider.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 30.04.2026.
//

import Foundation

/// A dependency provider that holds a weak reference to its resolved instance.
///
/// `WeakProvider` is used to implement the `.weak` lifetime strategy. It creates a new instance
/// of a dependency only if an existing instance is no longer in memory. As long as another
/// object holds a strong reference to the resolved instance, this provider will return the
/// same cached instance. Once all strong references are lost and the instance is deallocated,
/// the provider will use its factory closure to instantiate a new one.
///
/// - Note: This provider is strictly for reference types (classes). Attempting to use it
///   with value types (structs or enums) will result in a runtime crash.
final class WeakProvider {
    
    /// A weak reference to the currently cached instance, if it is still alive in memory.
    private weak var weakInstance: AnyObject?
    
    /// The factory closure responsible for instantiating the dependency.
    private let factory: @Sendable (DependencyResolving) -> Any
    
    /// Initializes a new weak provider with the specified factory closure.
    ///
    /// - Parameter factory: A thread-safe closure that takes a `DependencyResolving` instance
    ///                      and returns the newly created dependency.
    init(
        factory: @escaping @Sendable (DependencyResolving) -> Any
    ) {
        self.factory = factory
    }
}

// MARK: - DependencyProvider

extension WeakProvider: DependencyProvider {
    
    /// Resolves and provides an instance of the dependency.
    ///
    /// If a valid instance is still held in memory elsewhere, this method returns the cached
    /// instance. Otherwise, it invokes the factory to create a new instance, caches it weakly,
    /// and returns it.
    ///
    /// - Parameter resolver: The resolver used to satisfy any nested dependencies during creation.
    /// - Returns: The resolved dependency instance.
    /// - Warning: Triggers a `fatalError` if the factory produces a value type, as weak references
    ///            require `AnyObject` conformance.
    func provide(using resolver: DependencyResolving) -> Any {
        if let existingInstance = weakInstance {
            return existingInstance
        }
        
        let newInstance = factory(resolver)
        
        guard type(of: newInstance) is AnyClass else {
            fatalError("[WeakProvider] Cannot use .weak lifetime with value types. '\(type(of: newInstance))' must be a class.")
        }
        
        weakInstance = newInstance as AnyObject
        return newInstance
    }
}
