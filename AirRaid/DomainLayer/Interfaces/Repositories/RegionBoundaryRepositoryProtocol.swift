//
//  RegionBoundaryRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Provides the outlines of the regions that alerts can cover.
protocol RegionBoundaryRepositoryProtocol {

    /// Fetches the outlines of all oblasts, including Kyiv and Sevastopol as separate regions.
    ///
    /// - Throws: An error if the boundary data is missing or malformed.
    func fetchBoundaries() async throws -> [RegionBoundary]
}
