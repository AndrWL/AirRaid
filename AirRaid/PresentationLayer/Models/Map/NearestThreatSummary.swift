//
//  NearestThreatSummary.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// The threat closest to the user, as a card over the map.
struct NearestThreatSummary: Hashable {

    // MARK: - Variables

    let threatID: String

    /// «Шахед», «Шахед ×3».
    let title: String

    /// The asset name of the threat's silhouette.
    let iconName: String

    /// «42 км».
    let distanceText: String

    /// «≈ 14 хв»; `nil` unless the threat flies the user's way.
    let arrivalText: String?

    init(
        threat: Threat,
        proximity: ThreatProximity
    ) {
        threatID = threat.id
        let countText = threat.count.flatMap { $0 > 1 ? " ×\($0)" : nil } ?? ""
        title = threat.displayName + countText
        iconName = ThreatIcon(threat).name
        distanceText = DisplayTime.distance(proximity.distanceKm)
        arrivalText = proximity.timeToArrival.map(DisplayTime.estimate)
    }
}

// MARK: - Nearest

extension NearestThreatSummary {

    /// The nearest threat with a known position within `radiusKm` of the user, or `nil` when there is none.
    static func nearest(
        among threats: [Threat],
        to user: GeoCoordinate,
        at date: Date,
        radiusKm: Double
    ) -> NearestThreatSummary? {
        threats
            .compactMap { threat in threat.proximity(to: user, at: date).map { (threat, $0) } }
            .filter { $0.1.distanceKm <= radiusKm }
            .min { $0.1.distanceKm < $1.1.distanceKm }
            .map { NearestThreatSummary(threat: $0.0, proximity: $0.1) }
    }
}
