//
//  RegionBoundaryDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Maps GeoJSON region features to domain ``RegionBoundary`` values.
nonisolated enum RegionBoundaryDTOMapper {

    /// Maps one feature.
    ///
    /// - Throws: ``RegionBoundaryMappingError`` if a position has fewer than two numbers or a polygon has no rings.
    static func map(_ feature: RegionBoundaryFeatureDTO) throws -> RegionBoundary {
        let rawPolygons: [[[[Double]]]]
        switch feature.geometry {
        case .polygon(let rings):
            rawPolygons = [rings]
        case .multiPolygon(let polygons):
            rawPolygons = polygons
        }

        return RegionBoundary(
            id: feature.properties.shapeISO,
            name: feature.properties.shapeName,
            polygons: try rawPolygons.map { try mapPolygon($0, regionID: feature.properties.shapeISO) }
        )
    }
}

// MARK: - Private methods

nonisolated private extension RegionBoundaryDTOMapper {

    static func mapPolygon(_ rings: [[[Double]]], regionID: String) throws -> GeoPolygon {
        guard let exterior = rings.first else {
            throw RegionBoundaryMappingError.emptyPolygon(regionID: regionID)
        }
        return GeoPolygon(
            exterior: try mapRing(exterior, regionID: regionID),
            holes: try rings.dropFirst().map { try mapRing($0, regionID: regionID) }
        )
    }

    static func mapRing(_ positions: [[Double]], regionID: String) throws -> [GeoCoordinate] {
        try positions.map { position in
            guard position.count >= 2 else {
                throw RegionBoundaryMappingError.invalidPosition(regionID: regionID)
            }
            return GeoCoordinate(latitude: position[1], longitude: position[0])
        }
    }
}
