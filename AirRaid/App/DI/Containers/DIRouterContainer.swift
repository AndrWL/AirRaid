//
//  DIRouterContainer.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import DependencyContainer

/// DI container for navigation router dependencies.
///
/// Uses its own `DefaultDependencyContainer` instance internally.
/// Dependencies are registered in `assemble(with:)` and exposed through `DIRouterContaining` properties.
///
/// ## Registering a new stack router
///
/// ```swift
/// private func registerHomeStackRouter() {
///     container.register(StackRouter.self, name: Constants.home, lifetime: .weak) { _ in
///         StackRouter()
///     }
/// }
/// ```
///
/// Stack routers are `.weak` so a flow's `NavigationPath` resets when the flow is dismissed.
/// Registration names live in a `private enum Constants` at the bottom of this file.
final class DIRouterContainer {

    /// The underlying container that handles the actual registration and resolution of dependencies.
    private let container: DependencyContaining

    /// Initializes a new router dependency container.
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

extension DIRouterContainer: DIAssembling {

    func assemble(with appContainer: DIAppContaining) {
        registerMapIntentChannel()
        registerMapStackRouter()
        registerFeedStackRouter()
        registerSettingsStackRouter()
        registerTabBarRouter()
    }
}

// MARK: - DIRouterContaining

extension DIRouterContainer: DIRouterContaining {

    var tabBarRouter: TabBarRouter {
        return container.resolve(TabBarRouter.self)
    }

    var mapIntentChannel: MapIntentChannel {
        return container.resolve(MapIntentChannel.self)
    }

    var mapStackRouter: StackRouter {
        return container.resolve(StackRouter.self, name: Constants.map)
    }

    var feedStackRouter: StackRouter {
        return container.resolve(StackRouter.self, name: Constants.feed)
    }

    var settingsStackRouter: StackRouter {
        return container.resolve(StackRouter.self, name: Constants.settings)
    }
}

// MARK: - Configuration

private extension DIRouterContainer {

    /// A singleton: the tab bar router sends on it and the map's router, rebuilt with its tab, listens.
    func registerMapIntentChannel() {
        container.register(MapIntentChannel.self, lifetime: .singleton) { _ in
            MapIntentChannel()
        }
    }

    func registerMapStackRouter() {
        container.register(StackRouter.self, name: Constants.map, lifetime: .weak) { _ in
            StackRouter()
        }
    }

    func registerFeedStackRouter() {
        container.register(StackRouter.self, name: Constants.feed, lifetime: .weak) { _ in
            StackRouter()
        }
    }

    func registerSettingsStackRouter() {
        container.register(StackRouter.self, name: Constants.settings, lifetime: .weak) { _ in
            StackRouter()
        }
    }

    /// Registers the main tab bar router.
    ///
    /// Holds references to all tab stack routers to coordinate cross-tab deep links and resets.
    func registerTabBarRouter() {
        container.register(TabBarRouter.self, lifetime: .weak) { resolver in
            TabBarRouter(
                mapStackRouter: resolver.resolve(StackRouter.self, name: Constants.map),
                feedStackRouter: resolver.resolve(StackRouter.self, name: Constants.feed),
                settingsStackRouter: resolver.resolve(StackRouter.self, name: Constants.settings),
                mapIntentChannel: resolver.resolve(MapIntentChannel.self)
            )
        }
    }
}

// MARK: - Constants

/// Unique names for named `StackRouter` registrations.
private enum Constants {
    static let map = "map"
    static let feed = "feed"
    static let settings = "settings"
}
