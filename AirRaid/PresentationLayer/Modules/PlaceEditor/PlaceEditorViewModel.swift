//
//  PlaceEditorViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation

/// The view model of a saved place's screen in the settings.
@Observable
final class PlaceEditorViewModel<Router: PlaceEditorRouterProtocol>: BaseViewModel {

    // MARK: - Variables

    let radiusOptions = PlaceSettings.radiusOptions
    var name = ""
    private(set) var savedPlace: SavedPlace?
    private(set) var isPlusActive = false
    private(set) var boundaries: [RegionBoundary] = []

    @ObservationIgnored
    private let placeID: SavedPlace.ID

    @ObservationIgnored
    private let router: Router

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let entitlementService: EntitlementServiceProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    /// The name field is filled once, from the stored name, so a later update does not overwrite what is being typed.
    @ObservationIgnored
    private var hasLoadedName = false

    init(
        placeID: SavedPlace.ID,
        router: Router,
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        entitlementService: EntitlementServiceProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol
    ) {
        self.placeID = placeID
        self.router = router
        self.placeSettingsRepository = placeSettingsRepository
        self.entitlementService = entitlementService
        self.regionBoundaryRepository = regionBoundaryRepository
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        placeSettingsRepository.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                guard let self else { return }
                apply(settings.place(id: placeID))
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

// MARK: - PlaceEditorViewModelProtocol

extension PlaceEditorViewModel: PlaceEditorViewModelProtocol {

    var place: SettingsPlaceContent? {
        savedPlace.map { place in
            SettingsPlaceContent(
                place: place,
                regionName: boundaries.first { $0.contains(place.coordinate) }?.name,
                isPlusActive: isPlusActive
            )
        }
    }

    var namePlaceholder: String {
        savedPlace?.address?.locality ?? WatchedPlaceKind.custom.title
    }

    func onAppear() async {
        if boundaries.isEmpty {
            // Only for the region under the address; without it the screen still works.
            boundaries = (try? await regionBoundaryRepository.fetchBoundaries()) ?? []
        }
    }

    func didCommitName() {
        guard let savedPlace, savedPlace.kind == .custom else { return }
        placeSettingsRepository.renamePlace(placeID, to: name)
    }

    func didSelectRadius(_ radiusKm: Double) {
        // Shown at once: the repository's update arrives a run loop later, and until then the picker would read the
        // old radius and jump back.
        savedPlace = savedPlace?.with(radiusKm: radiusKm)
        placeSettingsRepository.setRadius(radiusKm, forPlace: placeID)
    }

    func didTapMoveOnMap() {
        guard let savedPlace else { return }
        router.showPlacePickerOnMap(savedPlace.kind == .home ? .home : .move(id: placeID))
    }

    func didConfirmRemove() {
        placeSettingsRepository.removePlace(placeID)
        router.close()
    }
}

// MARK: - Private methods

private extension PlaceEditorViewModel {

    func apply(_ place: SavedPlace?) {
        savedPlace = place
        if !hasLoadedName, let place {
            name = place.name ?? ""
            hasLoadedName = true
        }
    }
}
