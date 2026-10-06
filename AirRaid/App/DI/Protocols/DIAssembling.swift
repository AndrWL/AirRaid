//
//  DIAssembling.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// A protocol for DI containers that register their dependencies during app startup.
///
/// Each sub-container (e.g., `DIServiceContainer`, `DIRepositoryContainer`) conforms to this protocol
/// and registers its dependencies inside the `assemble(with:)` method.
///
/// This protocol is **not visible to consumers** (ViewModels, UseCases, etc.).
/// Only `DIAppContainer` calls `assemble(with:)` during `setup()`.
///
/// ## How to use when adding a new sub-container
///
/// 1. Create your container class conforming to both `DIAssembling` and your public protocol.
/// 2. Register dependencies inside `assemble(with:)`.
/// 3. Use `appContainer` to access sibling containers when you need cross-container dependencies.
///
/// ```swift
/// extension DIStorageContainer: DIAssembling {
///     func assemble(with appContainer: DIAppContaining) {
///         let services = appContainer.services
///         container.register(CacheServiceProtocol.self, lifetime: .singleton) { _ in
///             CacheServiceImpl(keychain: services.keychainService)
///         }
///     }
/// }
/// ```
protocol DIAssembling {
    func assemble(with appContainer: DIAppContaining)
}
