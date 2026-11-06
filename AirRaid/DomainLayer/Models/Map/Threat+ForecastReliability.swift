//
//  Threat+ForecastReliability.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// Whether a threat's movement forecast is solid enough to draw on the map.
///
/// The forecast extrapolates the last known course; drones turn, circle and route around air defence, so a guess
/// drawn for every threat would often point the wrong way. Only threats whose position, speed and course all come from
/// the track itself qualify.
nonisolated extension Threat {

    /// A confirmed position, a speed measured along the track, and a course the track agrees with: the last leg of the
    /// track (at least two points) points within ``Constants/maxCourseDeviation`` of where the forecast moves the
    /// threat. A report like "Semenivka → Kobeliaky" sets the course to the target even when the track says otherwise.
    var hasReliableForecast: Bool {
        guard
            positionQuality == .confirmed,
            speedSource == .measured,
            speedKmh > 0,
            let position,
            let lastPoint = trail.last?.coordinate,
            lastPoint != position.coordinate,
            let course
        else { return false }
        let trackBearing = lastPoint.initialBearing(to: position.coordinate)
        let deviation = abs((course - trackBearing + 540).truncatingRemainder(dividingBy: 360) - 180)
        return deviation <= Constants.maxCourseDeviation
    }

    /// The forecast position to draw, or `nil` when the forecast is not reliable, has run out, or has not moved the
    /// threat yet.
    func reliableForecastCoordinate(at date: Date) -> GeoCoordinate? {
        guard hasReliableForecast, date < expiresAt, let position else { return nil }
        guard
            let predicted = predictedCoordinate(at: date),
            predicted.distance(to: position.coordinate) >= Constants.minForecastShiftKm
        else { return nil }
        return predicted
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    /// Degrees between the track's last leg and the forecast course that still count as the same direction.
    static let maxCourseDeviation: Double = 45

    /// Closer to the position than this, the forecast has not moved the threat: moving 0 km lands a rounding error
    /// away (49.8 comes back as 49.800000000000004), never exactly on it.
    static let minForecastShiftKm: Double = 0.001
}
