//
//  RegionBoundaryMappingError.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Why a region feature could not be mapped by ``RegionBoundaryDTOMapper``.
nonisolated enum RegionBoundaryMappingError: Error {

    /// A polygon had no rings.
    case emptyPolygon(regionID: String)

    /// A position had fewer than two numbers.
    case invalidPosition(regionID: String)
}
