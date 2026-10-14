//
//  TabBarProtocols.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import Foundation
import SwiftUI

/// A protocol defining the state and business logic for the main tab bar container.
///
/// Currently, it inherits basic capabilities from `BaseViewModelProtocol`. It can be expanded
/// to handle global tab-level business logic, such as badge counts, tab visibility rules,
/// or handling deep link business rules before delegating to the router.
protocol TabBarViewModelProtocol: BaseViewModelProtocol {

    /// The feed's bubbles changed since the user last looked, for the tab's badge; `0` hides it.
    var unreadFeedCount: Int { get }

    /// Called when the tab bar appears: starts the live connection.
    func onAppear()
}

/// A protocol defining the navigation actions for the main tab bar.
///
/// Conforming types manage the currently selected tab and provide methods
/// to switch between tabs programmatically from any part of the application.
@MainActor
protocol TabBarRouterProtocol: AnyObject, Observable {
    
    /// Switches the application's active tab.
    ///
    /// - Parameter tab: The target `AppTab` to switch to.
    func switchTo(_ tab: AppTab)

    /// Opens the Map tab with the home picker: a fixed pin in the centre, the map moves under it.
    func showHomePickerOnMap()

    /// Opens the Map tab with the threat's details, from another tab.
    func showThreatOnMap(id: String)
}

/// A factory protocol responsible for constructing the root-level views for each tab.
///
/// Conforming types encapsulate the creation of the distinct feature flows
/// (Map, Feed, Settings) that are embedded within the tab bar.
protocol TabBarFactoryProtocol {

    associatedtype Map: View

    associatedtype Feed: View

    associatedtype Settings: View

    /// Builds and returns the root flow view for the Map tab.
    @ViewBuilder func makeMap() -> Map

    /// Builds and returns the root flow view for the Feed tab.
    @ViewBuilder func makeFeed() -> Feed

    /// Builds and returns the root flow view for the Settings tab.
    @ViewBuilder func makeSettings() -> Settings
}
