//
//  DistrictBoundaryRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

import Foundation

/// Reads raion outlines from the GeoJSON file bundled with the app.
///
/// The file is OCHA COD-AB Ukraine ADM2 (raions after the 2020 reform), simplified, under CC BY-IGO —
/// the licenses screen must credit it (`THIRD_PARTY_NOTICES.md`).
struct DistrictBoundaryRepository {

    // MARK: - Variables

    private let bundle: Bundle

    init(
        bundle: Bundle = .main
    ) {
        self.bundle = bundle
    }
}

// MARK: - DistrictBoundaryRepositoryProtocol

extension DistrictBoundaryRepository: DistrictBoundaryRepositoryProtocol {

    func fetchBoundaries() async throws -> [DistrictBoundary] {
        guard let url = bundle.url(forResource: Constants.fileName, withExtension: Constants.fileExtension) else {
            throw BundledResourceError.fileNotFound(name: Constants.fileName)
        }
        return try await Self.decodeBoundaries(at: url)
    }
}

// MARK: - Private methods

private extension DistrictBoundaryRepository {

    /// Reads and decodes the file off the main actor: it is ~570 KB of coordinates.
    @concurrent
    nonisolated static func decodeBoundaries(at url: URL) async throws -> [DistrictBoundary] {
        let data = try Data(contentsOf: url)
        let collection = try JSONDecoder().decode(DistrictBoundaryCollectionDTO.self, from: data)
        return try collection.features.map(DistrictBoundaryDTOMapper.map)
    }
}

// MARK: - Constants

private enum Constants {
    static let fileName = "ukraine-raions"
    static let fileExtension = "geojson"
}
