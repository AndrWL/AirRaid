//
//  RegionDetailsViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation
import OSLog

/// The view model that follows one region in the live air situation: its alerts and the threats reported in it.
@Observable
final class RegionDetailsViewModel: BaseViewModel {

    // MARK: - Variables

    private(set) var regionName: String?
    private(set) var situation: AirSituation = .empty
    private(set) var isFavorite = false

    @ObservationIgnored
    private let regionID: String

    @ObservationIgnored
    private let airSituationRepository: AirSituationRepositoryProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let favoriteRegionsRepository: FavoriteRegionsRepositoryProtocol

    @ObservationIgnored
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    init(
        regionID: String,
        airSituationRepository: AirSituationRepositoryProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        favoriteRegionsRepository: FavoriteRegionsRepositoryProtocol
    ) {
        self.regionID = regionID
        self.airSituationRepository = airSituationRepository
        self.regionBoundaryRepository = regionBoundaryRepository
        self.favoriteRegionsRepository = favoriteRegionsRepository
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        airSituationRepository.situationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] situation in
                self?.situation = situation
            }
            .store(in: &cancellables)

        favoriteRegionsRepository.favoriteRegionIDsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self else { return }
                isFavorite = ids.contains(regionID)
            }
            .store(in: &cancellables)
    }
}

// MARK: - RegionDetailsViewModelProtocol

extension RegionDetailsViewModel: RegionDetailsViewModelProtocol {

    func content(at date: Date) -> RegionDetailsContent? {
        guard let regionName else { return nil }
        return RegionDetailsContent(
            title: regionName,
            coverage: situation.airRaidCoverage,
            regionID: regionID,
            alerts: situation.alerts(inRegion: regionID),
            threats: situation.threats(inRegion: regionID),
            now: date
        )
    }

    func onAppear() async {
        guard regionName == nil else { return }
        do {
            let boundaries = try await regionBoundaryRepository.fetchBoundaries()
            // An unknown id cannot come from a tap on the map, but show the code rather than nothing.
            regionName = boundaries.first { $0.id == regionID }?.name ?? regionID
        } catch {
            logger.error("Failed to load region boundaries: \(String(describing: error), privacy: .public)")
            regionName = regionID
        }
    }

    func didTapFavorite() {
        favoriteRegionsRepository.setFavorite(!isFavorite, regionID: regionID)
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "RegionDetails"
}
