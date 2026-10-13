//
//  HomeDetailsViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Combine
import Foundation

/// The view model that follows the home: its address, the air raid alert at its point and the threats in its radius.
@Observable
final class HomeDetailsViewModel: BaseViewModel {

    // MARK: - Variables

    let radiusOptions = PlaceSettings.radiusOptions
    private(set) var home: HomePlace?
    private(set) var situation: AirSituation = .empty
    private(set) var boundaries: [RegionBoundary] = []
    private(set) var districts: [DistrictBoundary] = []

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let airSituationRepository: AirSituationRepositoryProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let districtBoundaryRepository: DistrictBoundaryRepositoryProtocol

    init(
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        airSituationRepository: AirSituationRepositoryProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        districtBoundaryRepository: DistrictBoundaryRepositoryProtocol
    ) {
        self.placeSettingsRepository = placeSettingsRepository
        self.airSituationRepository = airSituationRepository
        self.regionBoundaryRepository = regionBoundaryRepository
        self.districtBoundaryRepository = districtBoundaryRepository
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        placeSettingsRepository.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.home = settings.home
            }
            .store(in: &cancellables)

        airSituationRepository.situationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] situation in
                self?.situation = situation
            }
            .store(in: &cancellables)
    }
}

// MARK: - HomeDetailsViewModelProtocol

extension HomeDetailsViewModel: HomeDetailsViewModelProtocol {

    var radiusKm: Double? {
        home?.radiusKm
    }

    func content(at date: Date) -> HomeDetailsContent? {
        guard let home else { return nil }
        let region = boundaries.first { $0.contains(home.coordinate) }
        return HomeDetailsContent(
            home: home,
            regionName: region?.name,
            alertLevel: alertLevel(at: home.coordinate, regionID: region?.id),
            threats: situation.threats,
            now: date
        )
    }

    func onAppear() async {
        // Only for the region's name and the alert at the point; without them the sheet still works.
        if boundaries.isEmpty {
            boundaries = (try? await regionBoundaryRepository.fetchBoundaries()) ?? []
        }
        if districts.isEmpty {
            districts = (try? await districtBoundaryRepository.fetchBoundaries()) ?? []
        }
    }

    func didSelectRadius(_ radiusKm: Double) {
        // Shown at once: the repository's update reaches this view model a run loop later, and until then the picker
        // would read the old radius and jump back.
        if let home {
            self.home = HomePlace(coordinate: home.coordinate, radiusKm: radiusKm, address: home.address)
        }
        placeSettingsRepository.setRadius(radiusKm, for: .home)
    }

    func didTapRemoveHome() {
        placeSettingsRepository.removeHome()
    }
}

// MARK: - Private methods

private extension HomeDetailsViewModel {

    /// The oblast's alert when the whole oblast is alerted, else the alert of the raion the home is in; a hromada
    /// alert counts for its raion, the way the map fills it.
    func alertLevel(at point: GeoCoordinate, regionID: String?) -> RegionAlertLevel? {
        let coverage = situation.airRaidCoverage
        if let regionID, let level = coverage.regions[regionID] {
            return level
        }
        let district = districts.first { district in
            district.key.regionID == regionID && district.polygons.contains { $0.contains(point) }
        }
        return district.flatMap { coverage.districts[$0.key]?.level }
    }
}
