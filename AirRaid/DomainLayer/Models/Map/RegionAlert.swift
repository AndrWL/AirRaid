//
//  RegionAlert.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// An official alert (alerts.in.ua) for one place: an oblast, or a raion, hromada, or city inside it.
///
/// A region can have several at once — e.g. two raions — so the map aggregates them per region
/// (``AirSituation/airRaidCoverage``).
nonisolated struct RegionAlert: Identifiable, Hashable, Sendable {

    /// A stable identifier of the place in alerts.in.ua; an update replaces the alert with the same id.
    let id: String

    /// What the alert is about.
    let kind: RegionAlertKind

    /// The official danger level, or `nil` when the source gives none.
    let level: RegionAlertLevel?

    /// How much of the region the alert covers.
    let scope: RegionAlertScope

    /// The place name as published, e.g. Bucha Raion.
    let name: String

    /// The ISO 3166-2 code of the oblast the place is in, matching ``RegionBoundary/id``.
    let regionID: String

    /// The raion the place is or lies in — set for raion and hromada alerts, `nil` for oblasts and cities.
    let district: DistrictKey?

    /// When the alert was declared.
    let startedAt: Date
}
