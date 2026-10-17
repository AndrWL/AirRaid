//
//  ThreatProximity.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// How far a threat is from the user and, when it flies their way, roughly how soon it could be overhead.
///
/// - Warning: An estimate built on another estimate (the forecast position). Show it as such.
nonisolated struct ThreatProximity: Hashable, Sendable {

    /// The great-circle distance from the threat's estimated position, in kilometres.
    let distanceKm: Double

    /// How far off the threat's position may be, in kilometres; `0` for a confirmed one.
    let uncertaintyKm: Double

    /// The distance is smaller than the position's own error, so it says nothing more than "somewhere around here".
    var isWithinUncertainty: Bool {
        uncertaintyKm > 0 && distanceKm < uncertaintyKm
    }

    /// The time to cover that distance at the threat's speed; `nil` unless its course points at the user and, when its
    /// target is known, the user is not past that target.
    let timeToArrival: TimeInterval?
}

// MARK: - Threat

nonisolated extension Threat {

    /// The threat's proximity to the user at the given moment, or `nil` when its place is not known well enough to
    /// measure from — a report with only a target or a region.
    func proximity(
        to user: GeoCoordinate,
        at date: Date
    ) -> ThreatProximity? {
        guard let position else { return nil }
        let current = predictedCoordinate(at: date) ?? position.coordinate
        let distanceKm = current.distance(to: user)
        return ThreatProximity(
            distanceKm: distanceKm,
            uncertaintyKm: positionQuality == .confirmed ? 0 : accuracyKm,
            timeToArrival: timeToArrival(from: current, to: user, distanceKm: distanceKm, at: date)
        )
    }
}

// MARK: - Private methods

nonisolated private extension Threat {

    /// Only for a moving threat whose course is within ``Constants/approachTolerance`` of the bearing to the user,
    /// and while its forecast is still current. A threat stops at its ``Threat/target``, so a user farther along the
    /// course than ``Constants/targetReachKm`` past the target gets no arrival.
    func timeToArrival(
        from current: GeoCoordinate,
        to user: GeoCoordinate,
        distanceKm: Double,
        at date: Date
    ) -> TimeInterval? {
        guard speedKmh > 0, let course, date < expiresAt else { return nil }
        let bearing = current.initialBearing(to: user)
        let difference = abs((course - bearing + 540).truncatingRemainder(dividingBy: 360) - 180)
        guard difference <= Constants.approachTolerance else { return nil }
        if let target, distanceKm > current.distance(to: target.coordinate) + Constants.targetReachKm {
            return nil
        }
        return distanceKm / speedKmh * Constants.secondsPerHour
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    /// Degrees either side of the bearing to the user that still count as flying their way.
    static let approachTolerance: Double = 30
    /// How far past the target a place still counts as reached: a target names a town, not a point.
    static let targetReachKm: Double = 10
    static let secondsPerHour: Double = 3_600
}
