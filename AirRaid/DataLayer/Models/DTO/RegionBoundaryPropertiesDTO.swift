//
//  RegionBoundaryPropertiesDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// The properties of an oblast feature in `ukraine-oblasts.geojson` (built from OCHA COD-AB). Only the fields the app uses are decoded.
nonisolated struct RegionBoundaryPropertiesDTO: Decodable, Sendable {

    /// The English region name as in OCHA COD-AB, e.g. `Kyivska`.
    let shapeName: String

    /// The ISO 3166-2 code, e.g. `UA-32`.
    let shapeISO: String
}
