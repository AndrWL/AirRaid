//
//  RegionBoundaryFeatureDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A GeoJSON `Feature` describing one region.
nonisolated struct RegionBoundaryFeatureDTO: Decodable, Sendable {

    let properties: RegionBoundaryPropertiesDTO
    let geometry: RegionGeometryDTO
}
