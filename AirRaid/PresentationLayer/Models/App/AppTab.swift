//
//  AppTab.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Defines the available primary tabs within the main application interface.
///
/// `AppTab` is used in conjunction with a tab bar router
/// to manage the currently selected tab and programmatically switch between them
/// across the application.
enum AppTab {

    /// The map tab.
    /// Displays the current air raid alert status by region.
    case map

    /// The alerts tab.
    /// Displays the list and history of air raid alerts.
    case alerts

    /// The settings tab.
    /// Provides access to notification preferences and general application settings.
    case settings
}
