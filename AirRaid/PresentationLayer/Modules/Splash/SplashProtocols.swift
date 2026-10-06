//
//  SplashProtocols.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 29.04.2026.
//

import Foundation

/// ViewModel contract for the splash screen.
///
/// Defines the actions that the `SplashView` can trigger during its lifecycle.
protocol SplashViewModelProtocol: BaseViewModelProtocol {
    
    /// Notifies the view model that the splash screen has finished its initial presentation or loading phase.
    ///
    /// Calling this method typically triggers the application to evaluate the user's current
    /// session state and navigate to the next appropriate flow (e.g., onboarding or main).
    func completeSplash()
}
