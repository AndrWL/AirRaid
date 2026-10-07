//
//  MapViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import Foundation
import OSLog

/// The view model that combines static region outlines with the live air situation.
@Observable
final class MapViewModel: BaseViewModel {

    // MARK: - Variables

    let styleURL: URL
    private(set) var boundaries: [RegionBoundary] = []
    private(set) var cities: [City] = []
    private(set) var alertedRegionIDs: Set<String> = []
    private(set) var threats: [Threat] = []

    @ObservationIgnored
    private let router: MapRouterProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let cityRepository: CityRepositoryProtocol

    @ObservationIgnored
    private let airSituationRepository: AirSituationRepositoryProtocol

    @ObservationIgnored
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    init(
        router: MapRouterProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        cityRepository: CityRepositoryProtocol,
        airSituationRepository: AirSituationRepositoryProtocol,
        styleURL: URL
    ) {
        self.router = router
        self.regionBoundaryRepository = regionBoundaryRepository
        self.cityRepository = cityRepository
        self.airSituationRepository = airSituationRepository
        self.styleURL = styleURL
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        airSituationRepository.situationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] situation in
                self?.apply(situation)
            }
            .store(in: &cancellables)
    }
}

// MARK: - MapViewModelProtocol

extension MapViewModel: MapViewModelProtocol {

    func onAppear() async {
        if boundaries.isEmpty {
            do {
                boundaries = try await regionBoundaryRepository.fetchBoundaries()
            } catch {
                reportBundledDataFailure(error, resource: "region boundaries")
            }
        }
        if cities.isEmpty {
            do {
                cities = try await cityRepository.fetchRegionalCenters()
            } catch {
                reportBundledDataFailure(error, resource: "regional centers")
            }
        }
    }
}

// MARK: - Private methods

private extension MapViewModel {

    func apply(_ situation: AirSituation) {
        alertedRegionIDs = Set(situation.alerts.map(\.regionID))
        threats = situation.threats
    }

    /// Map data ships with the app, so a failure here is a build problem, not a user-facing one.
    func reportBundledDataFailure(_ error: Error, resource: String) {
        logger.error("Failed to load \(resource, privacy: .public): \(String(describing: error), privacy: .public)")
        assertionFailure("[MapViewModel] Failed to load \(resource): \(error)")
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Map"
}
