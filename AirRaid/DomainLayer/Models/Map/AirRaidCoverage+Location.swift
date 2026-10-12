//
//  AirRaidCoverage+Location.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// Whether a point on the map is under an air raid alert.
///
/// Channels name places by name only, and the backend sometimes picks a namesake in another oblast; a threat
/// reported where there is no alert at all is likely misplaced, so the map shows it faded.
nonisolated extension AirRaidCoverage {

    /// Whether an alerted oblast or raion contains the point; a hromada alert counts for its whole raion, the same
    /// way the map fills it.
    func isAlerted(
        at point: GeoCoordinate,
        regions: [RegionBoundary],
        districts: [DistrictBoundary]
    ) -> Bool {
        let inRegion = regions.contains { region in
            self.regions[region.id] != nil && region.polygons.contains { $0.contains(point) }
        }
        return inRegion || districts.contains { district in
            self.districts[district.key] != nil && district.polygons.contains { $0.contains(point) }
        }
    }
}
