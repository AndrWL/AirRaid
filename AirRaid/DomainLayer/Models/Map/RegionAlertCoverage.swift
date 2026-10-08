//
//  RegionAlertCoverage.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// The air raid state of one raion, aggregated from all its alerts, for filling it on the map.
///
/// Each part is the highest among the raion's alerts: one red hromada makes it red, a raion alert makes it whole.
nonisolated struct RegionAlertCoverage: Hashable, Sendable {

    /// How much of the raion is under alert — the map's fill strength.
    let extent: RegionAlertExtent

    /// The highest danger level — the map's fill color.
    let level: RegionAlertLevel

    /// The coverage of both alerts together.
    func combined(with other: RegionAlertCoverage) -> RegionAlertCoverage {
        RegionAlertCoverage(extent: max(extent, other.extent), level: max(level, other.level))
    }
}
