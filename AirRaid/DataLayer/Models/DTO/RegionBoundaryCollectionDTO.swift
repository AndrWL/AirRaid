//
//  RegionBoundaryCollectionDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A GeoJSON `FeatureCollection` of region outlines, as shipped in `ukraine-oblasts.geojson`.
nonisolated struct RegionBoundaryCollectionDTO: Decodable, Sendable {

    let features: [RegionBoundaryFeatureDTO]
}
