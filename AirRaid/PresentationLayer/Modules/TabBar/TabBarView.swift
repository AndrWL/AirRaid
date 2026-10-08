//
//  TabBarView.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import SwiftUI

/// The primary tab bar container view for the application.
///
/// `TabBarView` is responsible for displaying the main bottom navigation interface.
/// It observes a bound `selectedTab` state to support programmatic navigation (e.g., via deep links
/// or cross-module routing) and uses a `TabBarFactoryProtocol` to dynamically resolve and build
/// the views for each tab's content.
///
/// - Requires: A factory type conforming to `TabBarFactoryProtocol` to build the individual flows.
struct TabBarView<Factory: TabBarFactoryProtocol>: View {
    
    /// The view model that manages the state and business logic for the tab bar container.
    private let viewModel: TabBarViewModelProtocol
    
    /// A two-way binding to the currently selected application tab.
    /// This allows external components (like a global tab router) to control the active tab.
    @Binding private var selectedTab: AppTab
    
    /// The factory used to construct the root views for each specific tab.
    private let factory: Factory
    
    /// Initializes the tab bar view with its required dependencies.
    ///
    /// - Parameters:
    ///   - viewModel: An object conforming to `TabBarViewModelProtocol` to handle tab-level interactions.
    ///   - factory: A factory to build the views for each tab.
    ///   - selectedTab: A binding to the `AppTab` representing the currently active tab.
    init(
        viewModel: TabBarViewModelProtocol,
        factory: Factory,
        selectedTab: Binding<AppTab>
    ) {
        self.viewModel = viewModel
        self.factory = factory
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            factory.makeMap()
                .tag(AppTab.map)
                .tabItem { Label("Map", systemImage: "map") }

            factory.makeAlerts()
                .tag(AppTab.alerts)
                .tabItem { Label("Alerts", systemImage: "exclamationmark.triangle") }

            factory.makeSettings()
                .tag(AppTab.settings)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    @Previewable @State var selectedTab: AppTab = .map
    let container = DIAppContainer()
    let _ = container.setup()

    TabBarView(
        viewModel: TabBarViewModel(
            router: TabBarRouter(
                mapStackRouter: StackRouter(),
                alertsStackRouter: StackRouter(),
                settingsStackRouter: StackRouter()
            ),
            realtimeService: container.services.realtimeService
        ),
        factory: TabBarFactory(appContainer: container),
        selectedTab: $selectedTab
    )
}
