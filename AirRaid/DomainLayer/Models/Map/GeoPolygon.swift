//
//  GeoPolygon.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A polygon with optional holes.
///
/// Holes matter: Kyiv Oblast has a hole where the city of Kyiv is, so the two regions can be
/// filled independently without overlapping.
nonisolated struct GeoPolygon: Hashable, Sendable {

    /// The outer ring.
    let exterior: [GeoCoordinate]

    /// Rings cut out of the exterior.
    let holes: [[GeoCoordinate]]
}
