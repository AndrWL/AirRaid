//
//  ThreatAreaDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// `{name, code, lat, lon}` — an event's region; `code` is ISO 3166-2:UA, or `UA` for the whole country.
nonisolated struct ThreatAreaDTO: Decodable, Sendable {

    let name: String
    let code: String
    let lat: Double
    let lon: Double
}
