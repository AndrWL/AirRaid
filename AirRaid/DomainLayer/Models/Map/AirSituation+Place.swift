//
//  AirSituation+Place.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// The air raid alert at one point — the home's — read the way the map fills it.
nonisolated extension AirSituation {

    /// The air raid alerts that cover a point in the oblast and the raion: the oblast's own (a Crimea-wide alert for
    /// Sevastopol too), a Kyiv or Sevastopol city alert, and the alerts of the raion or of a hromada inside it — a
    /// hromada counts for its whole raion, as the map fills it.
    ///
    /// - Parameters:
    ///   - regionID: The oblast the point is in, or `nil` outside every outline.
    ///   - district: The raion the point is in, or `nil` outside every raion (Kyiv and Sevastopol have none).
    func airRaidAlerts(
        regionID: String?,
        district: DistrictKey?
    ) -> [RegionAlert] {
        guard regionID != nil || district != nil else { return [] }
        return alerts.filter { alert in
            guard alert.kind == .airRaid else { return false }
            switch alert.scope {
            case .oblast:
                return alert.regionID == regionID
                    || regionID.map { Self.includedRegionIDs[alert.regionID]?.contains($0) == true } == true
            case .city:
                return alert.regionID == regionID && Self.cityRegionIDs.contains(alert.regionID)
            case .raion, .hromada:
                return district != nil && alert.district == district
            case .unknown:
                return false
            }
        }
    }

    /// The highest level among the alerts at the point and the earliest start, or `nil` when none covers it.
    func airRaidAlertSummary(
        regionID: String?,
        district: DistrictKey?
    ) -> (level: RegionAlertLevel, startedAt: Date)? {
        let alerts = airRaidAlerts(regionID: regionID, district: district)
        guard let startedAt = alerts.map(\.startedAt).min() else { return nil }
        let level = alerts.map { $0.level ?? .red }.max() ?? .red
        return (level, startedAt)
    }
}
