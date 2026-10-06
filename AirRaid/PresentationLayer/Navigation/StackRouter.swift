//
//  StackRouter.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 24.04.2026.
//

import Foundation
import SwiftUI

/// Default implementation of ``StackRouting``.
///
/// Owns a `NavigationPath` and provides push, pop, and reset operations.
/// Multiple feature routers within the same `NavigationStack` can share
/// a single `StackRouter` instance to stay synchronized on the same path.
///
/// ## Usage
///
/// ```swift
/// let stackRouter = StackRouter()
///
/// // Feature routers share the same instance
/// let homeRouter = HomeRouter(stackRouter: stackRouter)
/// let detailRouter = DetailRouter(stackRouter: stackRouter)
///
/// // Bind to NavigationStack
/// NavigationStack(path: $stackRouter.path) { ... }
/// ```
@Observable
final class StackRouter {
    
    /// The concrete navigation path representing the current stack state.
    var path = NavigationPath()
    
    // MARK: - Private Helpers
    
    /// Wraps a navigation state change in a transaction to control animation behavior.
    ///
    /// Since SwiftUI's `NavigationStack` is declarative, transitions are normally implicit.
    /// To bypass these animations, this helper sets `disablesAnimations` to `true`
    /// within a `withTransaction` block.
    ///
    /// - Parameters:
    ///   - animated: A flag indicating if the standard transition should be shown.
    ///   - action: The closure containing the logic to modify the `NavigationPath`.
    private func performAction(animated: Bool, action: () -> Void) {
        if animated {
            action()
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                action()
            }
        }
    }
}

// MARK: - StackRouting

extension StackRouter: StackRouting {
    
    /// Appends a new route to the internal navigation path with animation control.
    func push<T: Hashable>(_ route: T, animated: Bool) {
        performAction(animated: animated) {
            path.append(route)
        }
    }
    
    /// Simultaneously appends an array of routes.
    ///
    /// If `animated` is `false`, the entire set of screens will appear instantly,
    /// which is the recommended approach for deep-linking and state restoration.
    func push<T: Hashable>(_ routes: [T], animated: Bool) {
        for route in routes {
            push(route, animated: animated)
        }
    }
    
    /// Safely removes the last route from the path, navigating back one screen.
    /// Does nothing if the navigation path is already empty.
    func pop(animated: Bool) {
        guard !path.isEmpty else { return }
        
        performAction(animated: animated) {
            path.removeLast()
        }
    }
    
    /// Clears all routes from the path, instantly navigating back to the root view.
    func popToRoot(animated: Bool) {
        performAction(animated: animated) {
            path.removeLast(path.count)
        }
    }
}
