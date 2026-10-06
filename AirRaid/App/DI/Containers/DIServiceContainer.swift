//
//  DIServiceContainer.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import DependencyContainer
import Foundation
import WebSocketClient

/// DI container for service-layer dependencies (network, keychain, analytics, etc.).
///
/// Uses its own `DefaultDependencyContainer` instance internally.
/// Dependencies are registered in `assemble(with:)` and exposed through `DIServiceContaining` properties.
///
/// ## Lifetime guidelines
///
/// - `.singleton` — stateful or expensive services (network client, keychain, analytics).
/// - `.transient` — stateless or lightweight services.
final class DIServiceContainer {

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

extension DIServiceContainer: DIAssembling {

    func assemble(with appContainer: DIAppContaining) {
        registerRealtimeService()
    }
}

// MARK: - DIServiceContaining

extension DIServiceContainer: DIServiceContaining {

    var realtimeService: RealtimeServiceProtocol {
        return container.resolve(RealtimeServiceProtocol.self)
    }
}

// MARK: - Configuration

private extension DIServiceContainer {

    func registerRealtimeService() {
        container.register(RealtimeServiceProtocol.self, lifetime: .singleton) { _ in
            guard let url = URL(string: AppEnvironment.webSocketURLString) else {
                fatalError("[RealtimeService] Invalid WebSocket URL: \(AppEnvironment.webSocketURLString)")
            }
            let client = WebSocketClient(
                configuration: WebSocketClientConfiguration(
                    url: url,
                    // TODO: Add the `Authorization` header from the keychain service once auth exists.
                    headersProvider: { [:] }
                )
            )
            // Factories are nonisolated; services are resolved from the main thread (CoordinatorViews, Factories).
            return MainActor.assumeIsolated {
                RealtimeService(client: client)
            }
        }
    }
}
