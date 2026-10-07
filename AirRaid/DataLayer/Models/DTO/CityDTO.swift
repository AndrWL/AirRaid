//
//  CityDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A city as stored in `ukraine-regional-centers.json`.
nonisolated struct CityDTO: Decodable, Sendable {

    let name: String
    let latitude: Double
    let longitude: Double
}
