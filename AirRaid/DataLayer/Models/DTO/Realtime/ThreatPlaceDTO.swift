//
//  ThreatPlaceDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// `{name, lat, lon}` — an event's `position` or `target`.
nonisolated struct ThreatPlaceDTO: Decodable, Sendable {

    let name: String
    let lat: Double
    let lon: Double
}
