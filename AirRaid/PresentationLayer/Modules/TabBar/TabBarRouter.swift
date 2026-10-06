//
//  TabBarRouter.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import Foundation

/// The global coordinator for tab-based navigation.
///
/// `TabBarRouter` maintains the state of the currently selected tab. It also holds references
/// to the individual `StackRouting` instances for each tab. This allows the tab router to perform
/// advanced navigation tasks, such as resetting a tab's navigation stack to its root when
/// the user taps an already-selected tab, or orchestrating complex cross-tab deep links.
@Observable
final class TabBarRouter {

    /// The currently active application tab. Updating this property will update the UI.
    var selectedTab: AppTab = .map

    /// The technical stack router managing the Map flow.
    @ObservationIgnored
    private let mapStackRouter: StackRouting

    /// The technical stack router managing the Alerts flow.
    @ObservationIgnored
    private let alertsStackRouter: StackRouting

    /// The technical stack router managing the Settings flow.
    @ObservationIgnored
    private let settingsStackRouter: StackRouting

    /// Initializes the tab bar router with the stack routers for each individual tab.
    ///
    /// - Parameters:
    ///   - mapStackRouter: The routing stack for the Map feature.
    ///   - alertsStackRouter: The routing stack for the Alerts feature.
    ///   - settingsStackRouter: The routing stack for the Settings feature.
    init(
        mapStackRouter: StackRouting,
        alertsStackRouter: StackRouting,
        settingsStackRouter: StackRouting
    ) {
        self.mapStackRouter = mapStackRouter
        self.alertsStackRouter = alertsStackRouter
        self.settingsStackRouter = settingsStackRouter
    }
}

// MARK: - TabBarRouterProtocol

extension TabBarRouter: TabBarRouterProtocol {

    /// Changes the currently active tab.
    ///
    /// - Parameter tab: The target `AppTab`.
    func switchTo(_ tab: AppTab) {
        selectedTab = tab
    }
}
