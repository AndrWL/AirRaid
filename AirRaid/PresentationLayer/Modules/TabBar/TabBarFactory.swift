//
//  TabBarFactory.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import Foundation
import SwiftUI

/// A concrete factory that constructs the root views for the application's tabs.
///
/// `TabBarFactory` resolves the dependencies for each feature flow (Map, Feed, Settings)
/// via the injected DI container and returns the fully assembled views.
@MainActor
struct TabBarFactory {

    /// The dependency injection container used to provide necessary services
    /// and dependencies to the created views.
    private let appContainer: DIAppContaining

    /// Initializes the tab bar factory with a dependency injection container.
    ///
    /// - Parameter appContainer: An object conforming to `DIAppContaining` that provides access
    ///                           to the app's registered dependencies.
    init(
        appContainer: DIAppContaining
    ) {
        self.appContainer = appContainer
    }
}

// MARK: - TabBarFactoryProtocol

extension TabBarFactory: TabBarFactoryProtocol {

    @ViewBuilder
    func makeMap() -> some View {
        MapCoordinatorView(
            appContainer: appContainer,
            factory: MapFactory(appContainer: appContainer)
        )
    }

    @ViewBuilder
    func makeFeed() -> some View {
        FeedCoordinatorView(
            appContainer: appContainer,
            factory: FeedFactory(appContainer: appContainer)
        )
    }

    @ViewBuilder
    func makeSettings() -> some View {
        SettingsCoordinatorView(
            appContainer: appContainer,
            factory: SettingsFactory(appContainer: appContainer)
        )
    }
}
