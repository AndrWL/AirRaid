//
//  AirSituation.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A snapshot of everything the map shows: active alerts and spotted threats.
///
/// Delivered as a whole snapshot rather than as deltas, so a subscriber never has to reconcile state.
nonisolated struct AirSituation: Hashable, Sendable {

    /// Active official alerts of every kind; a region may have several (one per raion, hromada, or city).
    let alerts: [RegionAlert]

    /// Threats currently spotted.
    let threats: [Threat]

    /// No alerts and no threats.
    static let empty = AirSituation(alerts: [], threats: [])
}

// MARK: - Computed properties

nonisolated extension AirSituation {

    /// Where the map fills air raid alerts.
    ///
    /// An oblast alert (or a Kyiv / Sevastopol city alert) fills the oblast; a raion alert fills the raion; a hromada
    /// alert fills its raion faintly. Other city alerts fill nothing — there are no city outlines. An alert without a
    /// level counts as red: it is a plain air raid alert.
    ///
    /// alerts.in.ua counts Sevastopol as part of Crimea, so a Crimea-wide alert fills Sevastopol too.
    var airRaidCoverage: AirRaidCoverage {
        var regions: [String: RegionAlertLevel] = [:]
        var districts: [DistrictKey: RegionAlertCoverage] = [:]
        for alert in alerts where alert.kind == .airRaid {
            let level = alert.level ?? .red
            switch alert.scope {
            case .oblast:
                for regionID in [alert.regionID] + (Self.includedRegionIDs[alert.regionID] ?? []) {
                    regions[regionID] = max(regions[regionID] ?? level, level)
                }
            case .city where Self.cityRegionIDs.contains(alert.regionID):
                regions[alert.regionID] = max(regions[alert.regionID] ?? level, level)
            case .raion, .hromada:
                guard let district = alert.district else { continue }
                let coverage = RegionAlertCoverage(extent: alert.scope == .raion ? .whole : .partial, level: level)
                districts[district] = districts[district]?.combined(with: coverage) ?? coverage
            case .city, .unknown:
                continue
            }
        }
        return AirRaidCoverage(regions: regions, districts: districts)
    }

    /// Cities that are regions of their own, so a city alert covers the whole region: Kyiv, Sevastopol.
    private static let cityRegionIDs: Set<String> = ["UA-30", "UA-40"]

    /// Regions an oblast-wide alert also covers: alerts.in.ua treats Sevastopol (UA-40) as part of Crimea (UA-43).
    private static let includedRegionIDs: [String: [String]] = ["UA-43": ["UA-40"]]
}
