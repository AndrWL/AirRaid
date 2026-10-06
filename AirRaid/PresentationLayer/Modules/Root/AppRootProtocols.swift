//
//  AppRootProtocols.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation
import SwiftUI

/// ViewModel contract for the root application view.
///
/// Exposes the current ``AppFlow`` and lifecycle methods that drive
/// the transition from splash to the appropriate flow (onboarding, auth, or main).
protocol AppRootViewModelProtocol: BaseViewModelProtocol {
    
    /// The currently active application flow.
    ///
    /// This property dictates which top-level section of the app (e.g., splash, onboarding,
    /// authentication, or main) should be presented to the user.
    var currentFlow: AppFlow { get }
}

/// Factory contract for building root-level flow views.
///
/// ``AppRootView`` uses this factory to create the view for each ``AppFlow`` case.
/// The concrete implementation lives in the App layer (``AppRootFactory``)
/// and has access to the DI container to build fully-wired views.
@MainActor
protocol RootFactory {
    
    /// The SwiftUI view type representing the initial splash or launch screen.
    associatedtype Splash: View
    
    /// The SwiftUI view type representing the onboarding sequence for new users.
    associatedtype Onboarding: View
    
    /// The SwiftUI view type representing the authentication flow (e.g., login or registration).
    associatedtype Authentication: View
    
    /// The SwiftUI view type representing the main authenticated application interface, typically a Tab Bar.
    associatedtype TabBar: View
    
    /// Builds and returns the view for the splash flow.
    ///
    /// - Returns: A fully assembled view of type `Splash`.
    @ViewBuilder func makeSplash() -> Splash
    
    /// Builds and returns the view for the onboarding flow.
    ///
    /// - Returns: A fully assembled view of type `Onboarding`.
    @ViewBuilder func makeOnboarding() -> Onboarding
    
    /// Builds and returns the view for the authentication flow.
    ///
    /// - Returns: A fully assembled view of type `Authentication`.
    @ViewBuilder func makeAuthentication() -> Authentication
    
    /// Builds and returns the view for the main application flow.
    ///
    /// - Returns: A fully assembled view of type `TabBar`.
    @ViewBuilder func makeTabBar() -> TabBar
}
