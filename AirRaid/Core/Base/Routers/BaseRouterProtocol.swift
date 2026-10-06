//
//  BaseRouterProtocol.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import Foundation
import SwiftUI

/// A foundational protocol for all feature-specific routers in the application.
///
/// Conforming types must be reference types (`AnyObject`) and support SwiftUI's
/// observation (`Observable`). It is restricted to the `@MainActor` to ensure
/// all UI-related navigation state changes are safely executed on the main thread.
@MainActor
protocol BaseRouterProtocol: AnyObject, Observable {
    
    var path: NavigationPath { get set }
}
