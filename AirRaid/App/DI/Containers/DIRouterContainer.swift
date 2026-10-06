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

    }
}

// MARK: - DIRouterContaining

extension DIRouterContainer: DIRouterContaining {

}
