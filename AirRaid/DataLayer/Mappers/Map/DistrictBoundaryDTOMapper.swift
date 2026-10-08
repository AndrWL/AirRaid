//
//  DistrictBoundaryDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// Maps the bundled raion GeoJSON to ``DistrictBoundary``.
nonisolated enum DistrictBoundaryDTOMapper {

    /// - Throws: ``RegionBoundaryMappingError`` if the geometry is malformed.
    static func map(_ feature: DistrictBoundaryFeatureDTO) throws -> DistrictBoundary {
        DistrictBoundary(
            id: feature.properties.id,
            key: DistrictKey(regionID: feature.properties.regionID, name: feature.properties.name),
            polygons: try GeoPolygonDTOMapper.map(feature.geometry, ownerID: feature.properties.id)
        )
    }
}
