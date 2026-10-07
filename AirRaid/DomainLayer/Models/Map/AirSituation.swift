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

    /// Active alerts, at most one per region.
    let alerts: [RegionAlert]

    /// Threats currently spotted.
    let threats: [Threat]

    /// No alerts and no threats.
    static let empty = AirSituation(alerts: [], threats: [])
}
