//
//  AppFlow.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 28.04.2026.
//

import Foundation

/// Represents the top-level application flow displayed by ``AppRootView``.
///
/// ``AppRootViewModel`` sets the active flow based on ``UserAccessState`` changes.
/// Transitions between flows are animated in the root view.
///
/// - `splash` — initial launch screen, shown while the app determines user access state.
/// - `onboarding` — first-time user experience.
/// - `authentication` — login / registration flow.
/// - `main` — primary app experience (tab bar, home, etc.).
enum AppFlow {
    
    /// The initial launch screen, shown while the app determines the user's access state.
    case splash
    
    /// The first-time user experience or tutorial flow.
    case onboarding
    
    /// The login and registration flow.
    case authentication
    
    /// The primary app experience (e.g., tab bar, home screen).
    case tabBar
}
