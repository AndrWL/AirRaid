//
//  GeoBoundingBox.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// The smallest latitude/longitude rectangle around a shape — what the camera fits to show it whole.
nonisolated struct GeoBoundingBox: Hashable, Sendable {

    let southWest: GeoCoordinate
    let northEast: GeoCoordinate

    /// Whether the point is inside the box grown by `margin` of its size on every side.
    func contains(
        _ point: GeoCoordinate,
        margin: Double = 0
    ) -> Bool {
        let latitudePadding = (northEast.latitude - southWest.latitude) * margin
        let longitudePadding = (northEast.longitude - southWest.longitude) * margin
        return (southWest.latitude - latitudePadding...northEast.latitude + latitudePadding).contains(point.latitude)
            && (southWest.longitude - longitudePadding...northEast.longitude + longitudePadding).contains(point.longitude)
    }
}

// MARK: - RegionBoundary

nonisolated extension RegionBoundary {

    /// The box around all of the region's polygons, or `nil` for a region without any.
    var boundingBox: GeoBoundingBox? {
        let points = polygons.flatMap(\.exterior)
        guard
            let minLatitude = points.map(\.latitude).min(),
            let maxLatitude = points.map(\.latitude).max(),
            let minLongitude = points.map(\.longitude).min(),
            let maxLongitude = points.map(\.longitude).max()
        else { return nil }
        return GeoBoundingBox(
            southWest: GeoCoordinate(latitude: minLatitude, longitude: minLongitude),
            northEast: GeoCoordinate(latitude: maxLatitude, longitude: maxLongitude)
        )
    }

    /// Whether the point is inside the region.
    func contains(_ point: GeoCoordinate) -> Bool {
        polygons.contains { $0.contains(point) }
    }
}
