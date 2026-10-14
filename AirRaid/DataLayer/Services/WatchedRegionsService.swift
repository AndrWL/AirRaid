//
//  WatchedRegionsService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation
import OSLog

/// Finds the oblasts of the watched places by the bundled outlines.
final class WatchedRegionsService {

    // MARK: - Variables

    private let watchedPlacesProvider: WatchedPlacesProviding
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol
    private let subject = CurrentValueSubject<Set<String>, Never>([])
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var boundaries: [RegionBoundary] = []
    private var places: [WatchedPlace] = []
    private var cancellables: Set<AnyCancellable> = []

    init(
        watchedPlacesProvider: WatchedPlacesProviding,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol
    ) {
        self.watchedPlacesProvider = watchedPlacesProvider
        self.regionBoundaryRepository = regionBoundaryRepository
        observe()
    }
}

// MARK: - WatchedRegionsProviding

extension WatchedRegionsService: WatchedRegionsProviding {

    var regionIDsPublisher: AnyPublisher<Set<String>, Never> {
        subject.removeDuplicates().eraseToAnyPublisher()
    }
}

// MARK: - Private methods

private extension WatchedRegionsService {

    func observe() {
        watchedPlacesProvider.placesPublisher
            .sink { [weak self] places in
                self?.places = places
                self?.refresh()
            }
            .store(in: &cancellables)

        Task { [weak self] in
            await self?.loadBoundaries()
        }
    }

    func loadBoundaries() async {
        do {
            boundaries = try await regionBoundaryRepository.fetchBoundaries()
        } catch {
            logger.error("Failed to load outlines: \(String(describing: error), privacy: .public)")
        }
        refresh()
    }

    func refresh() {
        let regionIDs = places.compactMap { place in
            boundaries.first { $0.contains(place.coordinate) }?.id
        }
        subject.send(Set(regionIDs))
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "WatchedRegions"
}
