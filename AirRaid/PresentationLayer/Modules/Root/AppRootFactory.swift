//
//  AppRootFactory.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation
import SwiftUI

/// Concrete implementation of ``RootFactory`` that builds views for each ``AppFlow``.
///
/// Lives in the App layer and has access to ``DIAppContaining`` to create
/// fully-wired views with their dependencies.
@MainActor
struct AppRootFactory {
    
    /// The dependency injection container used to provide necessary services
    /// and dependencies to the created views.
    private let appContainer: DIAppContaining
    
    /// Initializes the root factory with a dependency injection container.
    ///
    /// - Parameter appContainer: An object conforming to `DIAppContaining` that provides access
    ///                           to the app's registered dependencies.
    init(
        appContainer: DIAppContaining
    ) {
        self.appContainer = appContainer
    }
}

// MARK: - RootFactory

extension AppRootFactory: RootFactory {
    
    @ViewBuilder
    func makeSplash() -> some View {
        let viewModel = SplashViewModel(
            userAccessService: appContainer.services.userAccessService
        )
        
        SplashView(viewModel: viewModel)
    }
    
    // TODO: Replace placeholders with the Onboarding / Authentication modules once they exist.

    @ViewBuilder
    func makeOnboarding() -> some View {
        Text("Onboarding")
    }

    @ViewBuilder
    func makeAuthentication() -> some View {
        Text("Authentication")
    }
    
    @ViewBuilder
    func makeTabBar() -> some View {
        TabBarCoordinatorView(
            appContainer: appContainer,
            factory: TabBarFactory(appContainer: appContainer)
        )
    }
}
