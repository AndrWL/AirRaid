//
//  BaseRouter.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import Foundation
import SwiftUI

/// A foundational base class for feature-specific routers.
///
/// `BaseRouter` provides the common infrastructure needed for routing across different
/// features. It holds a reference to the shared `StackRouting` instance, allowing
/// subclassed feature routers to mutate the shared navigation path.
@Observable @MainActor
class BaseRouter {
    
    /// The underlying technical router responsible for managing the actual navigation stack's path.
    @ObservationIgnored
    let stackRouter: StackRouting
    
    /// Initializes the base router with the required stack router dependency.
    ///
    /// - Parameter stackRouter: The shared technical router managing the `NavigationPath`
    ///   for the current flow.
    init(
        stackRouter: StackRouting
    ) {
        self.stackRouter = stackRouter
    }
}

// MARK: - BaseRouterProtocol

extension BaseRouter: BaseRouterProtocol {
    
    var path: NavigationPath {
        get {
            return stackRouter.path
        }
        set {
            stackRouter.path = newValue
        }
    }
}
