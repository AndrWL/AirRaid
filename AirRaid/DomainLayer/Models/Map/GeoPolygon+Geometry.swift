//
//  GeoPolygon+Geometry.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// Planar geometry in degrees: good enough to tell which raion a point is in, not for measuring.
///
/// Outlines are a few hundred vertices each and a point is tested against a handful of alerted ones, so plain ray
/// casting is fast enough to run on every forecast tick.
nonisolated extension GeoPolygon {

    /// Whether the point is inside the outer ring and outside every hole — Kyiv Oblast has a hole where Kyiv is.
    func contains(_ point: GeoCoordinate) -> Bool {
        exterior.encloses(point) && !holes.contains { $0.encloses(point) }
    }
}

// MARK: - Ring geometry

nonisolated extension Array where Element == GeoCoordinate {

    /// Even-odd ray casting; the ring may or may not repeat its first vertex at the end.
    func encloses(_ point: GeoCoordinate) -> Bool {
        guard count >= 3 else { return false }
        var isInside = false
        var previous = self[count - 1]
        for current in self {
            if (current.latitude > point.latitude) != (previous.latitude > point.latitude) {
                let fraction = (point.latitude - current.latitude) / (previous.latitude - current.latitude)
                let longitude = current.longitude + fraction * (previous.longitude - current.longitude)
                if longitude > point.longitude {
                    isInside.toggle()
                }
            }
            previous = current
        }
        return isInside
    }

    /// The shoelace area, positive for a counter-clockwise ring.
    var signedArea: Double {
        var doubleArea = 0.0
        for (start, end) in edges {
            doubleArea += start.longitude * end.latitude - end.longitude * start.latitude
        }
        return doubleArea / 2
    }

    var centroid: GeoCoordinate {
        let area = signedArea
        guard area != 0 else {
            let count = Double(self.count)
            return GeoCoordinate(
                latitude: map(\.latitude).reduce(0, +) / count,
                longitude: map(\.longitude).reduce(0, +) / count
            )
        }
        var latitude = 0.0
        var longitude = 0.0
        for (start, end) in edges {
            let cross = start.longitude * end.latitude - end.longitude * start.latitude
            longitude += (start.longitude + end.longitude) * cross
            latitude += (start.latitude + end.latitude) * cross
        }
        return GeoCoordinate(latitude: latitude / (6 * area), longitude: longitude / (6 * area))
    }

    /// The middle of the longest segment where the parallel runs inside the ring.
    func widestCrossing(atLatitude latitude: Double) -> GeoCoordinate? {
        let longitudes = crossings(atLatitude: latitude).sorted()
        let widest = Swift.stride(from: 0, to: longitudes.count - 1, by: 2)
            .max { longitudes[$0 + 1] - longitudes[$0] < longitudes[$1 + 1] - longitudes[$1] }
        return widest.map { GeoCoordinate(latitude: latitude, longitude: (longitudes[$0] + longitudes[$0 + 1]) / 2) }
    }
}

// MARK: - Private methods

nonisolated private extension Array where Element == GeoCoordinate {

    /// Longitudes where the parallel crosses the ring's edges.
    func crossings(atLatitude latitude: Double) -> [Double] {
        edges.compactMap { start, end in
            guard (start.latitude > latitude) != (end.latitude > latitude) else { return nil }
            let fraction = (latitude - start.latitude) / (end.latitude - start.latitude)
            return start.longitude + fraction * (end.longitude - start.longitude)
        }
    }

    /// Consecutive vertex pairs, closing the ring.
    var edges: [(GeoCoordinate, GeoCoordinate)] {
        indices.map { (self[$0], self[($0 + 1) % count]) }
    }
}
