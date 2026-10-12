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

    /// The alerts and threats of the region with this ISO 3166-2 code.
    case regionDetails(id: String)

    /// One identity for every threat and region, so tapping another pin or region while the sheet is open updates
    /// the sheet in place instead of presenting a new one — which would drop the height the user chose.
    var id: String {
        "details"
    }

    /// Starts at half height so the threat or region stays visible on the map above.
    var detents: Set<PresentationDetent> {
        switch self {
        case .threatDetails, .regionDetails: [.medium, .large]
        }
    }
}
