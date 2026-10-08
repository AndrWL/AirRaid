//
//  Threat+Prediction.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Where a threat probably is between reports.
///
/// Channels report every few minutes; between reports the threat is moved from its last confirmed
/// ``Threat/position`` at ``Threat/speedKmh`` — toward its ``Threat/target`` when one is known, otherwise
/// along its ``Threat/heading``. Same algorithm as the backend's `predict()`.
///
/// - Warning: An estimate. Show it apart from the confirmed position and never present it as a fact.
nonisolated extension Threat {

    /// The estimated location at the given moment, or `nil` when the threat should not be moved:
    /// no position, zero speed, or neither a target nor a heading.
    ///
    /// The forecast stops after 15 minutes and at ``expiresAt``, and never overshoots the target.
    func predictedCoordinate(at date: Date) -> GeoCoordinate? {
        guard let position, speedKmh > 0 else { return nil }

        let maxElapsed = min(Constants.maxForecast, expiresAt.timeIntervalSince(movedAt))
        let elapsed = min(max(date.timeIntervalSince(movedAt), 0), max(maxElapsed, 0))
        let distanceKm = speedKmh * elapsed / Constants.secondsPerHour

        if let target {
            return position.coordinate.moved(toward: target.coordinate, distanceKm: distanceKm)
        }
        if let heading {
            return position.coordinate.moved(bearing: heading, distanceKm: distanceKm)
        }
        return nil
    }
}

// MARK: - GeoCoordinate

nonisolated private extension GeoCoordinate {

    /// The point `distanceKm` along the great circle toward `destination`, stopping at it.
    func moved(
        toward destination: GeoCoordinate,
        distanceKm: Double
    ) -> GeoCoordinate {
        let totalKm = distance(to: destination)
        guard distanceKm < totalKm else { return destination }
        return moved(bearing: initialBearing(to: destination), distanceKm: distanceKm)
    }

    /// The point `distanceKm` away along the great circle that starts at `bearing` degrees from north.
    func moved(
        bearing: Double,
        distanceKm: Double
    ) -> GeoCoordinate {
        let angularDistance = distanceKm / Constants.earthRadiusKm
        let bearingRad = bearing.radians
        let lat1 = latitude.radians
        let lon1 = longitude.radians

        let lat2 = asin(sin(lat1) * cos(angularDistance) + cos(lat1) * sin(angularDistance) * cos(bearingRad))
        let lon2 = lon1 + atan2(
            sin(bearingRad) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2)
        )
        return GeoCoordinate(latitude: lat2.degrees, longitude: lon2.degrees)
    }

    /// Great-circle (haversine) distance in kilometres.
    func distance(to other: GeoCoordinate) -> Double {
        let deltaLat = (other.latitude - latitude).radians
        let deltaLon = (other.longitude - longitude).radians
        let haversine = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(latitude.radians) * cos(other.latitude.radians) * sin(deltaLon / 2) * sin(deltaLon / 2)
        return 2 * Constants.earthRadiusKm * asin(min(1, sqrt(haversine)))
    }

    /// The bearing in degrees from north at which the great circle to `other` starts.
    func initialBearing(to other: GeoCoordinate) -> Double {
        let lat1 = latitude.radians
        let lat2 = other.latitude.radians
        let deltaLon = (other.longitude - longitude).radians
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        return atan2(y, x).degrees
    }
}

// MARK: - Double

nonisolated private extension Double {

    var radians: Double {
        self * .pi / 180
    }

    var degrees: Double {
        self * 180 / .pi
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let maxForecast: TimeInterval = 15 * 60
    static let secondsPerHour: Double = 3_600
    static let earthRadiusKm: Double = 6_371
}
