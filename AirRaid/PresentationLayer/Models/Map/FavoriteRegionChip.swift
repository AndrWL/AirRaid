//
//  FavoriteRegionChip.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// A followed region in the strip over the map: its short name and air raid state.
struct FavoriteRegionChip: Identifiable, Hashable {

    // MARK: - Variables

    /// The ISO 3166-2 code.
    let id: String

    /// «Полтавська», «Київ», «Крим» — the strip has no room for «область».
    let name: String

    let status: RegionAlertStatus

    init(
        region: RegionBoundary,
        coverage: AirRaidCoverage
    ) {
        id = region.id
        name = Constants.shortNames[region.id]
            ?? region.name.replacingOccurrences(of: Constants.oblastSuffix, with: "")
        status = RegionAlertStatus(coverage: coverage, regionID: region.id)
    }
}

// MARK: - Constants

private enum Constants {
    static let oblastSuffix = " область"
    static let shortNames = ["UA-43": "Крим"]
}
