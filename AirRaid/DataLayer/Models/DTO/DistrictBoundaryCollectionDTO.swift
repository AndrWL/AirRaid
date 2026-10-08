//
//  DistrictBoundaryCollectionDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// The bundled raion GeoJSON (`ukraine-raions.geojson`): a FeatureCollection of polygons.
nonisolated struct DistrictBoundaryCollectionDTO: Decodable, Sendable {

    let features: [DistrictBoundaryFeatureDTO]
}
