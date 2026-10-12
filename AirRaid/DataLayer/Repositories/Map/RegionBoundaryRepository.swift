//
//  RegionBoundaryRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Reads region outlines from the GeoJSON file bundled with the app.
///
/// The file is the union of the raions in `ukraine-raions.geojson` (OCHA COD-AB Ukraine ADM2, CC BY-IGO), so oblast
/// and raion borders match exactly and follow the coastline — no sea area is filled.
///
/// Decodes the file once and keeps the result: the map and every region sheet ask for it.
final class RegionBoundaryRepository {

    // MARK: - Variables

    private let bundle: Bundle

    /// The first decode, shared by callers that ask while it is still running.
    private var loading: Task<[RegionBoundary], Error>?

    init(
        bundle: Bundle = .main
    ) {
        self.bundle = bundle
    }
}

// MARK: - RegionBoundaryRepositoryProtocol

extension RegionBoundaryRepository: RegionBoundaryRepositoryProtocol {

    func fetchBoundaries() async throws -> [RegionBoundary] {
        if let loading {
            return try await loading.value
        }
        guard let url = bundle.url(forResource: Constants.fileName, withExtension: Constants.fileExtension) else {
            throw BundledResourceError.fileNotFound(name: Constants.fileName)
        }
        let task = Task { try await Self.decodeBoundaries(at: url) }
        loading = task
        do {
            return try await task.value
        } catch {
            // A broken bundle stays broken, but do not keep the failure around in case it was transient.
            loading = nil
            throw error
        }
    }
}

// MARK: - Private methods

private extension RegionBoundaryRepository {

    /// Reads and decodes the file off the main actor: it is ~260 KB of coordinates.
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
