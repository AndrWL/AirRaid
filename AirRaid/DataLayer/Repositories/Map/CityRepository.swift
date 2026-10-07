//
//  CityRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Reads the labelled cities from the JSON file bundled with the app.
///
/// The base map's tiles hold only capitals at country zoom, so regional centers come from here.
struct CityRepository {

    // MARK: - Variables

    private let bundle: Bundle

    init(
        bundle: Bundle = .main
    ) {
        self.bundle = bundle
    }
}

// MARK: - CityRepositoryProtocol

extension CityRepository: CityRepositoryProtocol {

    func fetchRegionalCenters() async throws -> [City] {
        guard let url = bundle.url(forResource: Constants.fileName, withExtension: Constants.fileExtension) else {
            throw BundledResourceError.fileNotFound(name: Constants.fileName)
        }
        return try await Self.decodeCities(at: url)
    }
}

// MARK: - Private methods

private extension CityRepository {

    @concurrent
    nonisolated static func decodeCities(at url: URL) async throws -> [City] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([CityDTO].self, from: data).map(CityDTOMapper.map)
    }
}

// MARK: - Constants

private enum Constants {
    static let fileName = "ukraine-regional-centers"
    static let fileExtension = "json"
}
