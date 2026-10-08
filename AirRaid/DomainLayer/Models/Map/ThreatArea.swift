//
//  ThreatArea.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// The region a threat is reported in.
nonisolated struct ThreatArea: Hashable, Sendable {

    /// The region name, in Ukrainian.
    let name: String

    /// The ISO 3166-2 code, matching ``RegionBoundary/id``, or ``countryWideRegionID`` for the whole country.
    let regionID: String

    /// The region's center — the fallback location when nothing more precise is known.
    let center: GeoCoordinate

    /// The code the backend uses for a report that covers the whole country.
    static let countryWideRegionID = "UA"

    var isCountryWide: Bool {
        regionID == Self.countryWideRegionID
    }
}
