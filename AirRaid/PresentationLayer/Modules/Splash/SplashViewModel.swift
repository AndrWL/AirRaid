//
//  SplashViewModel.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 29.04.2026.
//

import Foundation

/// The view model responsible for managing the business logic of the splash screen.
///
/// `SplashViewModel` coordinates the transition away from the splash screen by telling
/// the `UserAccessService` to evaluate the user's initial state once the splash view is ready.
@Observable
final class SplashViewModel: BaseViewModel {
    
    /// The service responsible for determining the user's authentication and onboarding status.
    @ObservationIgnored
    private let userAccessService: UserAccessServiceProtocol
    
    /// Initializes the splash view model with the specified user access service.
    ///
    /// - Parameter userAccessService: A service conforming to `UserAccessServiceProtocol` used
    ///                                to resolve the initial state of the application.
    init(
        userAccessService: UserAccessServiceProtocol
    ) {
        self.userAccessService = userAccessService
    }
}

// MARK: - SplashViewModelProtocol

extension SplashViewModel: SplashViewModelProtocol {
    
    func completeSplash() {
        userAccessService.resolveInitialState()
    }
}
