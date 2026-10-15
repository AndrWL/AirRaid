//
//  PlacesViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation

/// The view model that edits the watched places: the radius around the user and around each saved place, and the
/// home pin.
@Observable
final class PlacesViewModel: BaseViewModel {

    // MARK: - Variables

    let radiusOptions = PlaceSettings.radiusOptions
    private(set) var locationAuthorization: LocationAuthorization = .notDetermined
    private(set) var settings: PlaceSettings = .initial
    private(set) var boundaries: [RegionBoundary] = []
    private(set) var userLocation: GeoCoordinate?
    private(set) var isPlusActive = false

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let userLocationService: UserLocationServiceProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let entitlementService: EntitlementServiceProtocol

    init(
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        userLocationService: UserLocationServiceProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        entitlementService: EntitlementServiceProtocol
    ) {
        self.placeSettingsRepository = placeSettingsRepository
        self.userLocationService = userLocationService
        self.regionBoundaryRepository = regionBoundaryRepository
        self.entitlementService = entitlementService
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        placeSettingsRepository.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)

        userLocationService.authorizationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorization in
                self?.locationAuthorization = authorization
            }
            .store(in: &cancellables)

        userLocationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.userLocation = location
            }
            .store(in: &cancellables)

        entitlementService.isPlusActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.isPlusActive = isActive
            }
            .store(in: &cancellables)
    }
}

// MARK: - PlacesViewModelProtocol

extension PlacesViewModel: PlacesViewModelProtocol {

    var currentLocationRadiusKm: Double {
        settings.currentLocationRadiusKm
    }

    var canUseCurrentLocation: Bool {
        userLocation != nil
    }

    var homeRadiusKm: Double? {
        settings.home?.radiusKm
    }

    var homeID: SavedPlace.ID? {
        settings.home?.id
    }

    var homeRegionName: String? {
        guard let home = settings.home else { return nil }
        return boundaries.first { $0.contains(home.coordinate) }?.name
    }

    var customPlaces: [SavedPlace] {
        isPlusActive ? settings.customPlaces : []
    }

    func onAppear() async {
        guard boundaries.isEmpty else { return }
        // Only for the caption under the home; without it the sheet still works.
        boundaries = (try? await regionBoundaryRepository.fetchBoundaries()) ?? []
    }

    // Both shown at once: the repository's update arrives a run loop later, and until then the picker would read the
    // old radius and jump back.
    func didSelectCurrentLocationRadius(_ radiusKm: Double) {
        settings = settings.withCurrentLocationRadius(radiusKm)
        placeSettingsRepository.setCurrentLocationRadius(radiusKm)
    }

    func didSelectRadius(_ radiusKm: Double, forPlace id: SavedPlace.ID) {
        if let place = settings.place(id: id) {
            settings = settings.replacing(place.with(radiusKm: radiusKm))
        }
        placeSettingsRepository.setRadius(radiusKm, forPlace: id)
    }

    func didTapRemoveHome() {
        guard let home = settings.home else { return }
        placeSettingsRepository.removePlace(home.id)
    }

    func didTapUseCurrentLocation() {
        guard let userLocation else { return }
        placeSettingsRepository.setHome(at: userLocation)
    }
}
