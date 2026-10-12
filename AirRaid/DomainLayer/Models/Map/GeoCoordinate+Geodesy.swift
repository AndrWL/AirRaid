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
