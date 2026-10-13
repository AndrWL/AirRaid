//
//  ThreatDetailsViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Combine
import Foundation

/// The view model that follows one threat in the live air situation, together with the official alerts
/// in its region.
///
/// A threat that disappears from the situation keeps its last data and is marked gone, so the sheet does not
/// vanish under the user's finger.
@Observable
final class ThreatDetailsViewModel: BaseViewModel {

    // MARK: - Variables

    private(set) var threat: Threat?
    private(set) var regionAlerts: [RegionAlert] = []
    private(set) var isGone = false
    private(set) var places: [WatchedPlace] = []

    @ObservationIgnored
    private let threatID: String

    @ObservationIgnored
    private let airSituationRepository: AirSituationRepositoryProtocol

    @ObservationIgnored
    private let userLocationService: UserLocationServiceProtocol

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    init(
        threatID: String,
        airSituationRepository: AirSituationRepositoryProtocol,
        userLocationService: UserLocationServiceProtocol,
        placeSettingsRepository: PlaceSettingsRepositoryProtocol
    ) {
        self.threatID = threatID
        self.airSituationRepository = airSituationRepository
        self.userLocationService = userLocationService
        self.placeSettingsRepository = placeSettingsRepository
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

        userLocationService.locationPublisher
            .combineLatest(placeSettingsRepository.settingsPublisher)
            .map { WatchedPlace.places(currentLocation: $0, settings: $1) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] places in
                self?.places = places
            }
            .store(in: &cancellables)
    }
}

// MARK: - ThreatDetailsViewModelProtocol

extension ThreatDetailsViewModel: ThreatDetailsViewModelProtocol {

    func content(at date: Date) -> ThreatDetailsContent? {
        guard let threat else { return nil }
        return ThreatDetailsContent(
            threat: threat,
            alerts: regionAlerts,
            isGone: isGone,
            places: places,
            now: date
        )
    }
}

// MARK: - Private methods

private extension ThreatDetailsViewModel {

    func apply(_ situation: AirSituation) {
        if let current = situation.threats.first(where: { $0.id == threatID }) {
            threat = current
            isGone = false
        } else if threat != nil {
            isGone = true
        }
        guard let threat, !threat.isCountryWide else {
            regionAlerts = []
            return
        }
        regionAlerts = situation.alerts
            .filter { $0.regionID == threat.area.regionID }
            .sorted { $0.startedAt < $1.startedAt }
    }
}
