//
//  MapSheetRoute.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import SwiftUI

/// Defines the bottom sheet destinations for the Map flow.
nonisolated enum MapSheetRoute: Identifiable, Hashable {

    /// The details of the threat with this id.
    case threatDetails(id: String)

    /// One identity for every threat, so tapping another pin while the sheet is open updates the sheet in place
    /// instead of presenting a new one — which would drop the height the user chose.
    var id: String {
        switch self {
        case .threatDetails: "threatDetails"
        }
    }

    /// Starts at half height so the threat and its track stay visible on the map above.
    var detents: Set<PresentationDetent> {
        switch self {
        case .threatDetails: [.medium, .large]
        }
    }
}
