//
//  DistrictBoundary.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// The outline of a raion — the level below an oblast that most alerts are declared for.
nonisolated struct DistrictBoundary: Identifiable, Hashable, Sendable {

    /// A stable code from the boundary source, e.g. `UA0502`.
    let id: String

    /// How alerts refer to this raion.
    let key: DistrictKey

    /// One or more polygons.
    let polygons: [GeoPolygon]
}
