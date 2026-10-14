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

    /// The technical stack router managing the Feed flow.
    @ObservationIgnored
    private let feedStackRouter: StackRouting

    /// The technical stack router managing the Settings flow.
    @ObservationIgnored
    private let settingsStackRouter: StackRouting

    /// Requests for the Map tab that are not a route on its stack.
    @ObservationIgnored
    private let mapIntentChannel: MapIntentChannel

    /// Initializes the tab bar router with the stack routers for each individual tab.
    ///
    /// - Parameters:
    ///   - mapStackRouter: The routing stack for the Map feature.
    ///   - feedStackRouter: The routing stack for the Feed feature.
    ///   - settingsStackRouter: The routing stack for the Settings feature.
    ///   - mapIntentChannel: Carries requests to the Map tab.
    init(
        mapStackRouter: StackRouting,
        feedStackRouter: StackRouting,
        settingsStackRouter: StackRouting,
        mapIntentChannel: MapIntentChannel
    ) {
        self.mapStackRouter = mapStackRouter
        self.feedStackRouter = feedStackRouter
        self.settingsStackRouter = settingsStackRouter
        self.mapIntentChannel = mapIntentChannel
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

    func showHomePickerOnMap() {
        mapStackRouter.popToRoot(animated: false)
        selectedTab = .map
        mapIntentChannel.send(.pickHome)
    }

    func showThreatOnMap(id: String) {
        mapStackRouter.popToRoot(animated: false)
        selectedTab = .map
        mapIntentChannel.send(.showThreat(id: id))
    }
}
