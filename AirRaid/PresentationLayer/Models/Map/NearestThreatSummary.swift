//
//  NearestThreatSummary.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// The threat closest to one of the user's places, inside that place's radius, as a card over the map.
struct NearestThreatSummary: Hashable {

    // MARK: - Variables

    let threatID: String

    /// «Шахед», «Шахед ×3».
    let title: String

    /// The asset name of the threat's silhouette.
    let iconName: String

    /// «14 км від дому».
    let distanceText: String

    /// «≈ 4 хв»; `nil` unless the threat flies toward the place.
    let arrivalText: String?

    /// How many more threats are inside the radii; `0` when this is the only one.
    let otherCount: Int

    init(
        threat: Threat,
        place: WatchedPlaceKind,
        proximity: ThreatProximity,
        otherCount: Int
    ) {
        threatID = threat.id
        let countText = threat.count.flatMap { $0 > 1 ? " ×\($0)" : nil } ?? ""
        title = threat.displayName + countText
        iconName = ThreatIcon(threat).name
        distanceText = "\(DisplayTime.distance(proximity.distanceKm)) \(place.fromText)"
        arrivalText = proximity.timeToArrival.map(DisplayTime.estimate)
        self.otherCount = otherCount
    }
}

// MARK: - Nearest

extension NearestThreatSummary {

    /// The nearest threat with a known position inside the radius of any place, or `nil` when the radii are clear.
    static func nearest(
        among threats: [Threat],
        places: [WatchedPlace],
        at date: Date
    ) -> NearestThreatSummary? {
        // Each threat once, measured from the place it is closest to among those whose radius it is in.
        let inside = threats.compactMap { threat -> (Threat, WatchedPlaceKind, ThreatProximity)? in
            places
                .compactMap { place in
                    threat.proximity(to: place.coordinate, at: date)
                        .flatMap { $0.distanceKm <= place.radiusKm ? (threat, place.kind, $0) : nil }
                }
                .min { $0.2.distanceKm < $1.2.distanceKm }
        }
        guard let nearest = inside.min(by: { $0.2.distanceKm < $1.2.distanceKm }) else { return nil }
        return NearestThreatSummary(
            threat: nearest.0,
            place: nearest.1,
            proximity: nearest.2,
            otherCount: inside.count - 1
        )
    }
}
