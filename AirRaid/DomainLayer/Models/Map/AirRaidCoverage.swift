//
//  AirRaidCoverage.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// Which parts of the map are under an air raid alert, aggregated from all alerts, for filling them.
///
/// Every value is the highest among the alerts that hit the place: one red alert makes it red.
nonisolated struct AirRaidCoverage: Hashable, Sendable {

    /// Oblasts under a whole-oblast alert (Kyiv and Sevastopol city alerts included), by ISO 3166-2 code.
    let regions: [String: RegionAlertLevel]

    /// Raions under an alert: ``RegionAlertExtent/whole`` for a raion alert, ``RegionAlertExtent/partial`` when only
    /// a hromada inside it is alerted.
    let districts: [DistrictKey: RegionAlertCoverage]

    /// Nothing alerted.
    static let none = AirRaidCoverage(regions: [:], districts: [:])
}
