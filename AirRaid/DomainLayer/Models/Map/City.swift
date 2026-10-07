//
//  City.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A city labelled on the map.
nonisolated struct City: Hashable, Sendable {

    /// The Ukrainian name.
    let name: String

    /// Where the label is placed.
    let coordinate: GeoCoordinate
}
