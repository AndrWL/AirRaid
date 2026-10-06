//
//  SplashView.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 29.04.2026.
//

import Foundation
import SwiftUI

/// A view that displays the initial splash screen of the application.
///
/// `SplashView` is typically the first screen shown when the app launches.
/// It performs the initial visual presentation (e.g., animations) and notifies
/// its view model when the splash sequence is complete, allowing the app to
/// transition to the next appropriate flow.
struct SplashView: View {
    
    /// The view model that handles the business logic and lifecycle events for the splash screen.
    @State private var viewModel: SplashViewModelProtocol
    
    /// Initializes the splash view with a specified view model.
    ///
    /// - Parameter viewModel: An object conforming to `SplashViewModelProtocol` that manages
    ///                        the state and actions of the splash screen.
    init(
        viewModel: SplashViewModelProtocol
    ) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Text("Splash animation...")
            .task {
                // TODO: Replace call of 'completeSplash' when the app should display next flow
                try? await Task.sleep(for: .seconds(2))
                viewModel.completeSplash()
            }
    }
}

#Preview {
    SplashView(
        viewModel: SplashViewModel(
            userAccessService: UserAccessService()
        )
    )
}
