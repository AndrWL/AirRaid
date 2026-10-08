//
//  TabBarCoordinatorView.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import SwiftUI

/// The top-level coordinator responsible for managing the application's main Tab Bar interface.
///
/// `TabBarCoordinatorView` serves as the lifecycle anchor for the core navigation hub.
/// It ensures that the `TabBarViewModel` and `TabBarRouter` are preserved in memory
/// throughout the authenticated session. By utilizing `@State`, this coordinator
/// prevents the tab-switching logic and the selected tab state from being reset
/// during root-level view updates.
struct TabBarCoordinatorView<Factory: TabBarFactoryProtocol>: View {
    
    /// The persistent view model managing tab-level business logic and interactions.
    @State private var viewModel: TabBarViewModel
    
    /// The persistent router managing the selected tab state and deep-linking coordination.
    @State private var router: TabBarRouter
    
    /// The factory responsible for building the root views of each individual tab.
    private let factory: Factory
    
    /// Initializes the Tab Bar coordinator and anchors its state.
    ///
    /// - Parameters:
    ///   - appContainer: The DI container providing access to the shared Tab Bar router.
    ///   - factory: A factory conforming to `TabBarFactoryProtocol` to build tab content.
    init(
        appContainer: DIAppContaining,
        factory: Factory
    ) {
        let router = appContainer.routers.tabBarRouter
        let viewModel = TabBarViewModel(
            router: router,
            realtimeService: appContainer.services.realtimeService
        )
        
        self._router = State(wrappedValue: router)
        self._viewModel = State(wrappedValue: viewModel)
        self.factory = factory
    }
    
    var body: some View {
        TabBarView(
            viewModel: viewModel,
            factory: factory,
            selectedTab: $router.selectedTab
        )
    }
}

#Preview {
    let container = DIAppContainer()
    
    container.setup()
    
    return TabBarCoordinatorView(
        appContainer: container,
        factory: TabBarFactory(appContainer: container)
    )
}
