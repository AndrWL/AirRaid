//
//  DistrictBoundaryPropertiesDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// Properties written by the conversion from OCHA COD-AB ADM2 (see `THIRD_PARTY_NOTICES.md`).
nonisolated struct DistrictBoundaryPropertiesDTO: Decodable, Sendable {

    /// The COD-AB raion code, e.g. `UA0502`.
    let id: String

    /// The Ukrainian raion name without the word for "raion", e.g. `Haisynskyi`.
    let name: String

    /// The oblast's ISO 3166-2 code, e.g. `UA-05`.
    let regionID: String
}
