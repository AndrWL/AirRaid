//
//  PlaceDetailsViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Combine
import Foundation

/// The view model that follows a saved place: its address, the air raid alert at its point and the threats in its
/// radius.
@Observable
final class PlaceDetailsViewModel: BaseViewModel {

    // MARK: - Variables

    let radiusOptions = PlaceSettings.radiusOptions
    private(set) var place: SavedPlace?
    private(set) var situation: AirSituation = .empty
    private(set) var boundaries: [RegionBoundary] = []
    private(set) var districts: [DistrictBoundary] = []

    @ObservationIgnored
    private let placeID: SavedPlace.ID

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let airSituationRepository: AirSituationRepositoryProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let districtBoundaryRepository: DistrictBoundaryRepositoryProtocol

    init(
        placeID: SavedPlace.ID,
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        airSituationRepository: AirSituationRepositoryProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        districtBoundaryRepository: DistrictBoundaryRepositoryProtocol
    ) {
        self.placeID = placeID
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
                guard let self else { return }
                place = settings.place(id: placeID)
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

// MARK: - PlaceDetailsViewModelProtocol

extension PlaceDetailsViewModel: PlaceDetailsViewModelProtocol {

    var radiusKm: Double? {
        place?.radiusKm
    }

    var pick: PlacePick {
        place?.kind == .home ? .home : .move(id: placeID)
    }

    func content(at date: Date) -> PlaceDetailsContent? {
        guard let place else { return nil }
        let region = boundaries.first { $0.contains(place.coordinate) }
        return PlaceDetailsContent(
            place: place,
            regionName: region?.name,
            alertLevel: alertLevel(at: place.coordinate, regionID: region?.id),
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
        place = place?.with(radiusKm: radiusKm)
        placeSettingsRepository.setRadius(radiusKm, forPlace: placeID)
    }

    func didTapRemove() {
        placeSettingsRepository.removePlace(placeID)
    }
}

// MARK: - Private methods

private extension PlaceDetailsViewModel {

    /// The highest air raid alert at the point: its oblast's, or its raion's (a hromada alert counts for its raion,
    /// the way the map fills it).
    func alertLevel(at point: GeoCoordinate, regionID: String?) -> RegionAlertLevel? {
        let district = districts.first { district in
            district.key.regionID == regionID && district.polygons.contains { $0.contains(point) }
        }
        // The same rule as the widgets and the Live Activity, so the sheet never disagrees with the lock screen.
        return situation.airRaidAlertSummary(regionID: regionID, district: district?.key)?.level
    }
}
