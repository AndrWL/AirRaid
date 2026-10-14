//
//  NearestThreatSummary.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// The threat closest to one of the user's places, inside that place's radius, as a banner over the map.
struct NearestThreatSummary: Hashable, Identifiable {

    // MARK: - Variables

    let place: WatchedPlaceKind

    let threatID: String

    /// «Шахед», «Шахед ×3».
    let title: String

    /// The asset name of the threat's silhouette.
    let iconName: String

    /// «14 км від дому».
    let distanceText: String

    /// «≈ 4 хв»; `nil` unless the threat flies toward the place.
    let arrivalText: String?

    /// How many more threats are inside this place's radius; `0` when this is the only one.
    let otherCount: Int

    /// One banner per place.
    var id: WatchedPlaceKind { place }

    init(
        threat: Threat,
        place: WatchedPlaceKind,
        proximity: ThreatProximity,
        otherCount: Int
    ) {
        self.place = place
        threatID = threat.id
        title = threat.countedName
        iconName = ThreatIcon(threat).name
        distanceText = "\(DisplayTime.distance(proximity)) \(place.fromText)"
        arrivalText = proximity.timeToArrival.map(DisplayTime.estimate)
        self.otherCount = otherCount
    }
}

// MARK: - Nearest

extension NearestThreatSummary {

    /// For each place, the nearest threat inside its radius; places with a clear radius get none.
    ///
    /// Whether a threat is inside is decided by its reported position, the same rule that turns its pin red
    /// (``Threat/isNear(_:)``); the distance and the time shown are the estimate at `date`.
    static func nearest(
        among threats: [Threat],
        places: [WatchedPlace],
        at date: Date
    ) -> [NearestThreatSummary] {
        places.compactMap { place in
            let inside = threats
                .filter { $0.isNear([place]) }
                .compactMap { threat in threat.proximity(to: place.coordinate, at: date).map { (threat, $0) } }
            guard let nearest = inside.min(by: { $0.1.distanceKm < $1.1.distanceKm }) else { return nil }
            return NearestThreatSummary(
                threat: nearest.0,
                place: place.kind,
                proximity: nearest.1,
                otherCount: inside.count - 1
            )
        }
    }
}
