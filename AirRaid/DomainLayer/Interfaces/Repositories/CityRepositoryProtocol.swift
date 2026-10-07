//
//  CityRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Provides the cities labelled on the map.
protocol CityRepositoryProtocol {

    /// Fetches the regional centers: every oblast center plus Kyiv, Sevastopol, and Simferopol.
    ///
    /// - Throws: An error if the city data is missing or malformed.
    func fetchRegionalCenters() async throws -> [City]
}
