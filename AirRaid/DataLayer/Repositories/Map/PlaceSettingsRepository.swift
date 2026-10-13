//
//  PlaceSettingsRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation

/// Keeps the place settings in `UserDefaults`, on the device only: the home pin is where the user lives.
final class PlaceSettingsRepository {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let subject: CurrentValueSubject<PlaceSettings, Never>

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.subject = CurrentValueSubject(Self.load(from: defaults))
    }
}

// MARK: - PlaceSettingsRepositoryProtocol

extension PlaceSettingsRepository: PlaceSettingsRepositoryProtocol {

    var settingsPublisher: AnyPublisher<PlaceSettings, Never> {
        subject.eraseToAnyPublisher()
    }

    func setHome(at coordinate: GeoCoordinate) {
        let current = subject.value
        let radius = current.home?.radiusKm ?? PlaceSettings.defaultRadiusKm
        save(PlaceSettings(
            home: HomePlace(coordinate: coordinate, radiusKm: radius),
            currentLocationRadiusKm: current.currentLocationRadiusKm
        ))
    }

    func removeHome() {
        save(PlaceSettings(home: nil, currentLocationRadiusKm: subject.value.currentLocationRadiusKm))
    }

    func setRadius(_ radiusKm: Double, for kind: WatchedPlaceKind) {
        let current = subject.value
        switch kind {
        case .currentLocation:
            save(PlaceSettings(home: current.home, currentLocationRadiusKm: radiusKm))
        case .home:
            guard let home = current.home else { return }
            save(PlaceSettings(
                home: HomePlace(coordinate: home.coordinate, radiusKm: radiusKm),
                currentLocationRadiusKm: current.currentLocationRadiusKm
            ))
        }
    }
}

// MARK: - Private methods

private extension PlaceSettingsRepository {

    func save(_ settings: PlaceSettings) {
        guard settings != subject.value else { return }
        if let home = settings.home {
            defaults.set(home.coordinate.latitude, forKey: Constants.homeLatitudeKey)
            defaults.set(home.coordinate.longitude, forKey: Constants.homeLongitudeKey)
            defaults.set(home.radiusKm, forKey: Constants.homeRadiusKey)
        } else {
            [Constants.homeLatitudeKey, Constants.homeLongitudeKey, Constants.homeRadiusKey]
                .forEach(defaults.removeObject)
        }
        defaults.set(settings.currentLocationRadiusKm, forKey: Constants.currentLocationRadiusKey)
        subject.send(settings)
    }

    static func load(from defaults: UserDefaults) -> PlaceSettings {
        let currentRadius = defaults.object(forKey: Constants.currentLocationRadiusKey) as? Double
            ?? PlaceSettings.defaultRadiusKm
        guard
            let latitude = defaults.object(forKey: Constants.homeLatitudeKey) as? Double,
            let longitude = defaults.object(forKey: Constants.homeLongitudeKey) as? Double
        else {
            return PlaceSettings(home: nil, currentLocationRadiusKm: currentRadius)
        }
        let homeRadius = defaults.object(forKey: Constants.homeRadiusKey) as? Double ?? PlaceSettings.defaultRadiusKm
        return PlaceSettings(
            home: HomePlace(coordinate: GeoCoordinate(latitude: latitude, longitude: longitude), radiusKm: homeRadius),
            currentLocationRadiusKm: currentRadius
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let homeLatitudeKey = "homeLatitude"
    static let homeLongitudeKey = "homeLongitude"
    static let homeRadiusKey = "homeRadiusKm"
    static let currentLocationRadiusKey = "currentLocationRadiusKm"
}
