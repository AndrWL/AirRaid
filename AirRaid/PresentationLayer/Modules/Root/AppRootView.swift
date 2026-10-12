//
//  AppRootView.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import SwiftUI

/// The root view of the application that switches between top-level flows.
///
/// Displays the appropriate view for the current ``AppFlow`` (splash, onboarding,
/// authentication, or main) using a ``RootFactory`` to build each flow's view.
/// Transitions between flows are animated.
///
/// ## Assembly
///
/// ```swift
/// AppRootView(
///     factory: AppRootFactory(appContainer: container),
///     viewModel: AppRootViewModel(userAccessService: service)
/// )
/// ```
struct AppRootView<Factory: RootFactory>: View {
    
    /// The view model that manages the state and logic for the root view.
    /// It dictates which application flow is currently active.
    @State private var viewModel: AppRootViewModelProtocol
    
    /// The factory responsible for constructing the specific views for each flow.
    private let factory: Factory
    
    /// Initializes the root view with a specified factory and view model.
    ///
    /// - Parameters:
    ///   - factory: A factory conforming to `RootFactory` used to instantiate child views
    ///              for the splash, onboarding, authentication, and main flows.
    ///   - viewModel: An object conforming to `AppRootViewModelProtocol` that holds the
    ///                current flow state and logic.
    init(
        factory: Factory,
        viewModel: AppRootViewModelProtocol
    ) {
        self.factory = factory
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            switch viewModel.currentFlow {
            case .splash:
                factory.makeSplash()
            case .onboarding:
                factory.makeOnboarding()
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
            case .authentication:
                factory.makeAuthentication()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .tabBar:
                factory.makeTabBar()
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut, value: viewModel.currentFlow)
        // The app typeface for every Text that does not pick its own style.
        .font(.app(.body))
    }
}

#Preview {
    AppRootView(
        factory: AppRootFactory(
            appContainer: DIAppContainer()
        ),
        viewModel: AppRootViewModel(
            userAccessService: UserAccessService()
        )
    )
}
