//
//  GeoCoordinate.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A WGS 84 point.
///
/// Domain-owned so the Domain layer does not depend on CoreLocation or the map SDK.
/// - Note: `nonisolated` because geometry is decoded off the main actor.
nonisolated struct GeoCoordinate: Hashable, Sendable {

    /// Latitude in degrees, positive to the north.
    let latitude: Double

    /// Longitude in degrees, positive to the east.
    let longitude: Double
}
