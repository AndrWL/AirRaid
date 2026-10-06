//
//  UserAccessServiceProtocol.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation
import Combine

/// A service that tracks and manages the user's access state throughout the app lifecycle.
///
/// Provides both a synchronous snapshot (`state`) and a reactive stream (`statePublisher`)
/// of ``UserAccessState`` changes. The publisher is backed by a `CurrentValueSubject`,
/// so new subscribers immediately receive the current value.
///
/// ## Observing state changes
///
/// ```swift
/// userAccessService.statePublisher
///     .removeDuplicates()
///     .receive(on: DispatchQueue.main)
///     .sink { state in
///         // react to state change
///     }
/// ```
///
/// ## Mutating state
///
/// Call `completeOnboarding()`, `authenticate()`, or `logout()` to transition between states.
/// Each method publishes the new state through `statePublisher`.
protocol UserAccessServiceProtocol {
    
    /// The current synchronous snapshot of the user's access state.
    var state: UserAccessState { get }
    
    /// A reactive stream that publishes changes to the user's access state.
    var statePublisher: AnyPublisher<UserAccessState, Never> { get }
    
    /// Determines and sets the initial access state upon application launch.
    ///
    /// This method typically checks persistent storage (e.g., UserDefaults, Keychain)
    /// to determine if the user has already completed onboarding or has a valid authentication token.
    func resolveInitialState()
    
    /// Updates the access state to indicate that the user has completed the onboarding flow.
    func completeOnboarding()
    
    /// Updates the access state to indicate that the user has successfully logged in or signed up.
    func authenticate()
    
    /// Updates the access state to indicate that the user has logged out.
    ///
    /// This transitions the state back to `.unauthenticated` and should be accompanied by
    /// clearing local session data.
    func logout()
}
