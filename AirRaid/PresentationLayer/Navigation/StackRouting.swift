//
//  StackRouting.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 24.04.2026.
//

import Foundation
import SwiftUI

/// A protocol for managing push navigation within a single `NavigationStack`.
///
/// Conforming types own a `NavigationPath` and provide methods to push, pop,
/// and reset the navigation stack. This protocol is used at two levels:
///
/// - **App level**: `AppNavigator` holds references to `StackRouting` instances
///   for each tab to perform cross-feature navigation and deep linking.
/// - **Feature level**: Feature routers compose a `StackRouting` instance internally
///   to delegate push/pop operations. Multiple feature routers within the same
///   `NavigationStack` share a single `StackRouting` instance, which keeps them
///   synchronized on the same `NavigationPath`.
///
/// ## Sharing between routers
///
/// ```swift
/// let stackRouter = StackRouter()
/// let homeRouter = HomeRouter(stackRouter: stackRouter)
/// let detailRouter = DetailRouter(stackRouter: stackRouter) // same path
/// ```
///
/// ## Usage with NavigationStack
///
/// ```swift
/// NavigationStack(path: $stackRouter.path) {
///     RootView()
/// }
/// ```
protocol StackRouting: AnyObject, Observable {
    
    /// The underlying collection of routes driving the `NavigationStack`.
    ///
    /// You should bind this property to your stack using `@Bindable` or directly
    /// via `$path` depending on your observation setup.
    var path: NavigationPath { get set }
    
    /// Pushes a single route onto the navigation stack.
    ///
    /// - Parameters:
    ///   - route: The destination route to append to the path.
    ///   - animated: If `false`, the transition occurs instantly via a non-animated transaction.
    func push<T: Hashable>(_ route: T, animated: Bool)
    
    /// Pushes a sequence of routes onto the navigation stack simultaneously.
    ///
    /// This is particularly useful for deep-linking scenarios where the app needs to
    /// construct a specific navigation state (multiple screens) instantly.
    ///
    /// - Parameters:
    ///   - routes: An array of destination routes to append.
    ///   - animated: If `false`, all views in the sequence are presented without animation.
    func push<T: Hashable>(_ routes: [T], animated: Bool)
    
    /// Removes the top-most route from the stack, navigating back one screen.
    ///
    /// - Parameter animated: If `false`, the screen is dismissed instantly.
    func pop(animated: Bool)
    
    /// Clears the entire navigation path, returning the user to the root view.
    ///
    /// - Parameter animated: If `false`, the stack is reset without a visual transition.
    func popToRoot(animated: Bool)
}
