//
//  DistrictBoundaryFeatureDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

nonisolated struct DistrictBoundaryFeatureDTO: Decodable, Sendable {

    let properties: DistrictBoundaryPropertiesDTO
    let geometry: RegionGeometryDTO
}
