//
//  RegionBoundaryPropertiesDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// The properties of a geoBoundaries ADM1 feature. Only the fields the app uses are decoded.
nonisolated struct RegionBoundaryPropertiesDTO: Decodable, Sendable {

    /// The English region name, e.g. `Kyiv Oblast`.
    let shapeName: String

    /// The ISO 3166-2 code, e.g. `UA-32`.
    let shapeISO: String
}
