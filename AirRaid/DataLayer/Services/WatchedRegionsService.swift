//
//  WatchedRegionsService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation
import OSLog

/// Finds the oblasts of the home and the current location by the bundled outlines.
final class WatchedRegionsService {

    // MARK: - Variables

    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol
    private let userLocationService: UserLocationServiceProtocol
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol
    private let subject = CurrentValueSubject<Set<String>, Never>([])
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var boundaries: [RegionBoundary] = []
    private var settings: PlaceSettings = .initial
    private var location: GeoCoordinate?
    private var cancellables: Set<AnyCancellable> = []

    init(
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        userLocationService: UserLocationServiceProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol
    ) {
        self.placeSettingsRepository = placeSettingsRepository
        self.userLocationService = userLocationService
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
        placeSettingsRepository.settingsPublisher
            .sink { [weak self] settings in
                self?.settings = settings
                self?.refresh()
            }
            .store(in: &cancellables)

        userLocationService.locationPublisher
            .removeDuplicates()
            .sink { [weak self] location in
                self?.location = location
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
        let places = WatchedPlace.places(currentLocation: location, settings: settings)
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
