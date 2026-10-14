//
//  SettingsRoute.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

/// Defines the screens pushed onto the Settings stack.
enum SettingsRoute: Hashable {

    /// What the voice feed reads and how.
    case voice
}

/// Defines the sheets of the Settings tab.
enum SettingsSheetRoute: Identifiable {

    /// AirRaid Плюс: the subscription, its status and restoring it.
    case paywall

    var id: Self { self }
}
