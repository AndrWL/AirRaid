//
//  GeoCoordinate+Geodesy.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// Great-circle distances and bearings on a spherical Earth: within a fraction of a percent of the ellipsoid at
/// Ukraine's scale, which is plenty for a forecast.
nonisolated extension GeoCoordinate {

    /// The mean Earth radius.
    static let earthRadiusKm: Double = 6_371

    /// Great-circle (haversine) distance in kilometres.
    func distance(to other: GeoCoordinate) -> Double {
        let deltaLat = (other.latitude - latitude).radians
        let deltaLon = (other.longitude - longitude).radians
        let haversine = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(latitude.radians) * cos(other.latitude.radians) * sin(deltaLon / 2) * sin(deltaLon / 2)
        return 2 * Self.earthRadiusKm * asin(min(1, sqrt(haversine)))
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

    /// The point `distanceKm` away along the great circle that starts at `bearing` degrees from north.
    func moved(
        bearing: Double,
        distanceKm: Double
    ) -> GeoCoordinate {
        let angularDistance = distanceKm / Self.earthRadiusKm
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

    /// A ring of points `radiusKm` around this one, for drawing a radius on the map; the first point is not repeated.
    func circle(
        radiusKm: Double,
        segments: Int = 72
    ) -> [GeoCoordinate] {
        (0..<segments).map { index in
            moved(bearing: Double(index) * 360 / Double(segments), distanceKm: radiusKm)
        }
    }
}

// MARK: - Double

nonisolated extension Double {

    var radians: Double {
        self * .pi / 180
    }

    var degrees: Double {
        self * 180 / .pi
    }
}
