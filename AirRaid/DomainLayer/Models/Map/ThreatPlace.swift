//
//  ThreatPlace.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A named place a threat is at or heading to — usually a settlement the channels mention.
nonisolated struct ThreatPlace: Hashable, Sendable {

    /// The place name as reported, in Ukrainian.
    let name: String

    let coordinate: GeoCoordinate
}
