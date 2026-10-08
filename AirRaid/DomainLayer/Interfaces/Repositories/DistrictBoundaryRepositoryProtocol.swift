//
//  DistrictBoundaryRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// Provides raion outlines, so the map can fill exactly the raions an alert names.
protocol DistrictBoundaryRepositoryProtocol {

    /// Fetches the outlines of all raions (Kyiv and Sevastopol are regions, not raions, and are not included).
    ///
    /// - Throws: An error if the boundary data is missing or malformed.
    func fetchBoundaries() async throws -> [DistrictBoundary]
}
