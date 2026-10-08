//
//  GeoPolygonDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// Maps GeoJSON polygon geometry (`[lon, lat]` positions) to ``GeoPolygon``s; shared by region and raion outlines.
nonisolated enum GeoPolygonDTOMapper {

    /// - Parameters:
    ///   - geometry: A Polygon or MultiPolygon.
    ///   - ownerID: The outline's id, reported in errors.
    /// - Throws: ``RegionBoundaryMappingError`` if a position has fewer than two numbers or a polygon has no rings.
    static func map(
        _ geometry: RegionGeometryDTO,
        ownerID: String
    ) throws -> [GeoPolygon] {
        let rawPolygons: [[[[Double]]]]
        switch geometry {
        case .polygon(let rings):
            rawPolygons = [rings]
        case .multiPolygon(let polygons):
            rawPolygons = polygons
        }
        return try rawPolygons.map { try mapPolygon($0, ownerID: ownerID) }
    }
}

// MARK: - Private methods

nonisolated private extension GeoPolygonDTOMapper {

    static func mapPolygon(_ rings: [[[Double]]], ownerID: String) throws -> GeoPolygon {
        guard let exterior = rings.first else {
            throw RegionBoundaryMappingError.emptyPolygon(regionID: ownerID)
        }
        return GeoPolygon(
            exterior: try mapRing(exterior, ownerID: ownerID),
            holes: try rings.dropFirst().map { try mapRing($0, ownerID: ownerID) }
        )
    }

    static func mapRing(_ positions: [[Double]], ownerID: String) throws -> [GeoCoordinate] {
        try positions.map { position in
            guard position.count >= 2 else {
                throw RegionBoundaryMappingError.invalidPosition(regionID: ownerID)
            }
            return GeoCoordinate(latitude: position[1], longitude: position[0])
        }
    }
}
