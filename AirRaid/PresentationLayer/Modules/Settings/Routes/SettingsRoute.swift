//
//  SettingsRoute.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Defines the screens pushed onto the Settings stack.
enum SettingsRoute: Hashable {

    /// What the voice feed reads and how.
    case voice

    /// A saved place: its name, radius, moving and removing it.
    case place(id: SavedPlace.ID)
}

/// Defines the sheets of the Settings tab.
enum SettingsSheetRoute: Identifiable {

    /// AirRaid Plus: the subscription, its status and restoring it.
    case paywall

    var id: Self { self }
}
