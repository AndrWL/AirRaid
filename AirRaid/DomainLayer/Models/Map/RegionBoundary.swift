//
//  RegionBoundary.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// The outline of an administrative region that can be filled on the map when it has an alert.
nonisolated struct RegionBoundary: Identifiable, Hashable, Sendable {

    /// The ISO 3166-2 code, e.g. `UA-30` for the city of Kyiv and `UA-32` for Kyiv Oblast.
    ///
    /// Alerts reference regions by this code, so whatever source the backend uses must be mapped to it.
    let id: String

    /// The display name.
    let name: String

    /// One or more polygons — a region can have exclaves.
    let polygons: [GeoPolygon]
}
