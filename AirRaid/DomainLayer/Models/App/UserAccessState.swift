//
//  UserAccessState.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation

/// Represents the current user access level in the application.
///
/// Used by ``UserAccessServiceProtocol`` to communicate the user's authentication
/// and onboarding status. ``AppRootViewModel`` observes changes to this state
/// and switches the active ``AppFlow`` accordingly.
///
/// - `requiresOnboarding` — first launch, user has not completed onboarding.
/// - `unauthenticated` — onboarding complete, but user is not signed in.
/// - `authenticated` — user is signed in and has full access.
enum UserAccessState {
    
    /// Indicates it is the first launch and the user has not yet completed onboarding.
    case requiresOnboarding
    
    /// Indicates onboarding is complete, but the user is not currently signed in.
    case unauthenticated
    
    /// Indicates the user is signed in and has full access to the application.
    case authenticated
}
