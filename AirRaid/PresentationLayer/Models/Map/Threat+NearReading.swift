//
//  Threat+NearReading.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 16.10.2026.
//

import Foundation

/// What a banner, a widget or a place's card says about a threat inside a place's radius.
extension Threat {

    /// The distance and arrival to the place at `date`, or `nil` when the threat is near only by its target
    /// (``Threat/isHeading(into:)``): then there is no position to measure from.
    func nearProximity(
        to place: WatchedPlace,
        at date: Date
    ) -> ThreatProximity? {
        isHeading(into: place) ? nil : proximity(to: place.coordinate, at: date)
    }

    /// «курсом на Вишневе» — said in place of a distance when only the target is known.
    var headingText: String? {
        target.map { "курсом на \($0.name)" }
    }

    /// For ordering near threats: the measured distance, or how far the target is from the place.
    func nearDistanceKm(
        _ proximity: ThreatProximity?,
        to place: WatchedPlace
    ) -> Double {
        proximity?.distanceKm ?? target.map { $0.coordinate.distance(to: place.coordinate) } ?? place.radiusKm
    }
}
