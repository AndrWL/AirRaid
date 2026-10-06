//
//  UserAccessService.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation
import Combine

/// Concrete implementation of ``UserAccessServiceProtocol``.
///
/// Manages the user's access state using a `CurrentValueSubject` as the single source of truth.
/// On initialization, `actualizeAccessState()` is called to determine the initial state
/// based on persisted data (e.g., keychain tokens, onboarding flags).
///
/// ## Extending with real logic
///
/// Replace the placeholder in `actualizeAccessState()` with actual checks:
///
/// ```swift
/// private func actualizeAccessState() {
///     if keychainService.hasValidToken {
///         accessStatePublisher.send(.authenticated)
///     } else if userDefaults.hasCompletedOnboarding {
///         accessStatePublisher.send(.unauthenticated)
///     } else {
///         accessStatePublisher.send(.requiresOnboarding)
///     }
/// }
/// ```
final class UserAccessService {
    
    /// The internal subject that maintains the current state and broadcasts changes to subscribers.
    /// It is initialized with `.requiresOnboarding` as the default starting state.
    private var accessStatePublisher = CurrentValueSubject<UserAccessState, Never>(.requiresOnboarding)
}

// MARK: - UserAccessServiceProtocol

extension UserAccessService: UserAccessServiceProtocol {
    
    var statePublisher: AnyPublisher<UserAccessState, Never> {
        return accessStatePublisher.eraseToAnyPublisher()
    }
    
    var state: UserAccessState {
        return accessStatePublisher.value
    }
    
    func completeOnboarding() {
        accessStatePublisher.send(.unauthenticated)
    }
    
    func authenticate() {
        accessStatePublisher.send(.authenticated)
    }
    
    func logout() {
        accessStatePublisher.send(.unauthenticated)
    }
    
    func resolveInitialState() {
        // TODO: Replace with real checks (keychain, user defaults, etc.).
        // Goes straight to the tab bar until Onboarding / Authentication modules exist.

        accessStatePublisher.send(.authenticated)
    }
}
