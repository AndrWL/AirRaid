//
//  WatchedPlacesService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation

/// Builds the watched places from the location, the saved places and AirRaid Plus.
final class WatchedPlacesService {

    // MARK: - Variables

    private let subject = CurrentValueSubject<[WatchedPlace], Never>([])
    private var cancellables: Set<AnyCancellable> = []

    init(
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        userLocationService: UserLocationServiceProtocol,
        entitlementService: EntitlementServiceProtocol
    ) {
        Publishers.CombineLatest3(
            userLocationService.locationPublisher.removeDuplicates(),
            placeSettingsRepository.settingsPublisher.removeDuplicates(),
            entitlementService.isPlusActivePublisher.removeDuplicates()
        )
        .map { location, settings, isPlusActive in
            WatchedPlace.places(currentLocation: location, settings: settings, includesCustomPlaces: isPlusActive)
        }
        .removeDuplicates()
        .sink { [subject] places in
            subject.send(places)
        }
        .store(in: &cancellables)
    }
}

// MARK: - WatchedPlacesProviding

extension WatchedPlacesService: WatchedPlacesProviding {

    var placesPublisher: AnyPublisher<[WatchedPlace], Never> {
        subject.eraseToAnyPublisher()
    }
}

// MARK: - Preview

#if DEBUG
extension WatchedPlacesService {

    /// The places stored in the preview suite, without Plus.
    static var preview: WatchedPlacesService {
        WatchedPlacesService(
            placeSettingsRepository: PlaceSettingsRepository(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            userLocationService: UserLocationService(),
            entitlementService: StoreKitEntitlementService(productIDs: [])
        )
    }
}
#endif
