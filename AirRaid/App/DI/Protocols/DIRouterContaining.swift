//
//  DIRouterContaining.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// A protocol exposing resolved router dependencies.
///
/// Provides access to navigation routers registered in ``DIRouterContainer``.
/// Feature modules use this protocol to obtain router instances for their navigation flows.
///
/// ## Adding a new router
///
/// 1. Register the router in ``DIRouterContainer/assemble(with:)``.
/// 2. Add a computed property here that resolves and returns it.
///
/// ```swift
/// protocol DIRouterContaining {
///     var homeStackRouter: StackRouter { get }
/// }
/// ```
protocol DIRouterContaining {

}
