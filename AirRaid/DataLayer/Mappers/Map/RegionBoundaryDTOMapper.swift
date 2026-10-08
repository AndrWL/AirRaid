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
        RegionBoundary(
            id: feature.properties.shapeISO,
            name: feature.properties.shapeName,
            polygons: try GeoPolygonDTOMapper.map(feature.geometry, ownerID: feature.properties.shapeISO)
        )
    }
}
