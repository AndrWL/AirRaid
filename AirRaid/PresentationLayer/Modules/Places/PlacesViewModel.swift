//
//  PlacesViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation

/// The view model that edits the watched places: the radius around the user and around the home, and the home pin.
@Observable
final class PlacesViewModel: BaseViewModel {

    // MARK: - Variables

    let radiusOptions = PlaceSettings.radiusOptions
    private(set) var locationAuthorization: LocationAuthorization = .notDetermined
    private(set) var settings: PlaceSettings = .initial
    private(set) var boundaries: [RegionBoundary] = []
    private(set) var userLocation: GeoCoordinate?

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let userLocationService: UserLocationServiceProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    init(
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        userLocationService: UserLocationServiceProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol
    ) {
        self.placeSettingsRepository = placeSettingsRepository
        self.userLocationService = userLocationService
        self.regionBoundaryRepository = regionBoundaryRepository
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

    var homeRegionName: String? {
        guard let home = settings.home else { return nil }
        return boundaries.first { $0.contains(home.coordinate) }?.name
    }

    func onAppear() async {
        guard boundaries.isEmpty else { return }
        // Only for the caption under the home; without it the sheet still works.
        boundaries = (try? await regionBoundaryRepository.fetchBoundaries()) ?? []
    }

    func didSelectRadius(_ radiusKm: Double, for kind: WatchedPlaceKind) {
        // Shown at once: the repository's update arrives a run loop later, and until then the picker would read the
        // old radius and jump back.
        switch kind {
        case .currentLocation:
            settings = PlaceSettings(home: settings.home, currentLocationRadiusKm: radiusKm)
        case .home:
            if let home = settings.home {
                settings = PlaceSettings(
                    home: HomePlace(coordinate: home.coordinate, radiusKm: radiusKm, address: home.address),
                    currentLocationRadiusKm: settings.currentLocationRadiusKm
                )
            }
        }
        placeSettingsRepository.setRadius(radiusKm, for: kind)
    }

    func didTapRemoveHome() {
        placeSettingsRepository.removeHome()
    }

    func didTapUseCurrentLocation() {
        guard let userLocation else { return }
        placeSettingsRepository.setHome(at: userLocation)
    }
}
