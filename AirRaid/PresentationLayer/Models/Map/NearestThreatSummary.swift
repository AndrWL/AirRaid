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

    let place: WatchedPlace

    let threatID: String

    /// The threat's name, with its count when there are several.
    let title: String

    /// The asset name of the threat's silhouette.
    let iconName: String

    /// The distance from the place, or "heading for <target>" when only the target is known.
    let distanceText: String

    /// The estimated arrival; `nil` unless the threat flies toward the place.
    let arrivalText: String?

    /// How many more threats are inside this place's radius; `0` when this is the only one.
    let otherCount: Int

    /// One banner per place.
    var id: String { place.id }

    /// The distance, for ordering the banners.
    let distanceKm: Double

    init(
        threat: Threat,
        place: WatchedPlace,
        proximity: ThreatProximity?,
        otherCount: Int
    ) {
        self.place = place
        threatID = threat.id
        title = threat.countedName
        iconName = ThreatIcon(threat).name
        distanceText = proximity.map { "\(DisplayTime.distance($0)) \(place.fromText)" } ?? threat.headingText ?? ""
        arrivalText = proximity?.timeToArrival.map(DisplayTime.estimate)
        distanceKm = threat.nearDistanceKm(proximity, to: place)
        self.otherCount = otherCount
    }
}

// MARK: - Nearest

extension NearestThreatSummary {

    /// For each place, the nearest threat inside its radius; places with a clear radius get none.
    ///
    /// Whether a threat is inside is decided by its reported position, the same rule that turns its pin red
    /// (``Threat/isNear(_:)``); the distance and the time shown are the estimate at `date`. With many places, a threat
    /// is shown once, for its closest place, and the closest ``Constants/maxBanners`` banners are kept so the map stays
    /// visible.
    static func nearest(
        among threats: [Threat],
        places: [WatchedPlace],
        at date: Date
    ) -> [NearestThreatSummary] {
        let all = places.compactMap { place -> NearestThreatSummary? in
            let inside = threats
                .filter { $0.isNear(place) }
                .map { threat in (threat, threat.nearProximity(to: place, at: date)) }
            guard let nearest = inside.min(by: {
                $0.0.nearDistanceKm($0.1, to: place) < $1.0.nearDistanceKm($1.1, to: place)
            }) else { return nil }
            return NearestThreatSummary(
                threat: nearest.0,
                place: place,
                proximity: nearest.1,
                otherCount: inside.count - 1
            )
        }
        var shownThreatIDs: Set<String> = []
        let distinct = all
            .sorted { $0.distanceKm < $1.distanceKm }
            .filter { shownThreatIDs.insert($0.threatID).inserted }
        return Array(distinct.prefix(Constants.maxBanners))
    }
}

// MARK: - Constants

private enum Constants {
    static let maxBanners = 3
}
