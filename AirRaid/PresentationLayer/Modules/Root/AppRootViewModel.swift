//
//  AppRootViewModel.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation
import Combine

/// Root ViewModel that determines which top-level flow to display.
///
/// Subscribes to ``UserAccessServiceProtocol/statePublisher`` to react to access state changes
/// (e.g., after login, logout, or onboarding completion) and maps them to the corresponding ``AppFlow``.
///
/// ## Lifecycle
///
/// 1. Starts with ``AppFlow/splash``.
/// 2. On splash appear, subscribes to future access state changes.
/// 3. When splash completes, reads the current state and transitions to the appropriate flow.
/// 4. Subsequent state changes (login, logout) automatically update `currentFlow`.
@Observable
final class AppRootViewModel: BaseViewModel {
    
    /// The currently active application flow.
    ///
    /// This property drives the root view of the application. It starts as `.splash` by default
    /// and is updated automatically based on the user's access state.
    private(set) var currentFlow: AppFlow = .splash
    
    /// The service responsible for managing and broadcasting the user's authentication and access state.
    @ObservationIgnored
    private let userAccessService: UserAccessServiceProtocol
    
    /// Initializes the root view model with the specified user access service.
    ///
    /// - Parameter userAccessService: A service conforming to `UserAccessServiceProtocol` that provides
    ///                                the current user access state via a publisher.
    init(
        userAccessService: UserAccessServiceProtocol
    ) {
        self.userAccessService = userAccessService
    }
    
    // MARK: - Override methods
    
    /// Sets up the reactive bindings for the view model.
    ///
    /// This method is called to subscribe to relevant publishers, such as the user access state.
    override func setupBindings() {
        super.setupBindings()
        bindUserAccessState()
    }
    
    // MARK: - Private methods
    
    /// Updates the current application flow based on the provided user access state.
    ///
    /// - Parameter state: The new `UserAccessState` received from the service.
    private func updateFlow(with state: UserAccessState) {
        switch state {
        case .authenticated:
            currentFlow = .tabBar
        case .unauthenticated:
            currentFlow = .authentication
        case .requiresOnboarding:
            currentFlow = .onboarding
        }
    }
    
    /// Subscribes to the user access state publisher and handles state changes.
    ///
    /// This binding ignores the initial state (`dropFirst()`), filters out redundant updates (`removeDuplicates()`),
    /// and ensures that flow updates occur on the main thread.
    private func bindUserAccessState() {
        userAccessService.statePublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateFlow(with: state)
            }
            .store(in: &cancellables)
    }
}

// MARK: - AppRootViewModelProtocol

extension AppRootViewModel: AppRootViewModelProtocol {
    
}
