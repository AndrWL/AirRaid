//
//  RegionBoundaryRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Reads region outlines from the GeoJSON file bundled with the app.
///
/// The file is geoBoundaries `UKR ADM1` (simplified), built from OpenStreetMap data under ODbL —
/// the map must show "© OpenStreetMap contributors".
struct RegionBoundaryRepository {

    // MARK: - Variables

    private let bundle: Bundle

    init(
        bundle: Bundle = .main
    ) {
        self.bundle = bundle
    }
}

// MARK: - RegionBoundaryRepositoryProtocol

extension RegionBoundaryRepository: RegionBoundaryRepositoryProtocol {

    func fetchBoundaries() async throws -> [RegionBoundary] {
        guard let url = bundle.url(forResource: Constants.fileName, withExtension: Constants.fileExtension) else {
            throw BundledResourceError.fileNotFound(name: Constants.fileName)
        }
        return try await Self.decodeBoundaries(at: url)
    }
}

// MARK: - Private methods

private extension RegionBoundaryRepository {

    /// Reads and decodes the file off the main actor: it is ~750 KB of coordinates.
    @concurrent
    nonisolated static func decodeBoundaries(at url: URL) async throws -> [RegionBoundary] {
        let data = try Data(contentsOf: url)
        let collection = try JSONDecoder().decode(RegionBoundaryCollectionDTO.self, from: data)
        return try collection.features.map(RegionBoundaryDTOMapper.map)
    }
}

// MARK: - Constants

private enum Constants {
    static let fileName = "ukraine-oblasts"
    static let fileExtension = "geojson"
}
