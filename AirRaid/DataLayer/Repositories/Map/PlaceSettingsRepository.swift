//
//  PlaceSettingsRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation

/// Keeps the place settings in `UserDefaults`, on the device only: the home pin is where the user lives.
///
/// The home's address is looked up once, when the home is set (or for a home saved before addresses existed), and
/// stored with it.
final class PlaceSettingsRepository {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let addressResolver: PlaceAddressResolving?
    private let subject: CurrentValueSubject<PlaceSettings, Never>
    private var addressLookup: Task<Void, Never>?

    init(
        defaults: UserDefaults = .standard,
        addressResolver: PlaceAddressResolving? = nil
    ) {
        self.defaults = defaults
        self.addressResolver = addressResolver
        self.subject = CurrentValueSubject(Self.load(from: defaults))
        if let home = subject.value.home, home.address == nil {
            lookUpAddress(of: home.coordinate)
        }
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
        lookUpAddress(of: coordinate)
    }

    func removeHome() {
        addressLookup?.cancel()
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
                home: HomePlace(coordinate: home.coordinate, radiusKm: radiusKm, address: home.address),
                currentLocationRadiusKm: current.currentLocationRadiusKm
            ))
        }
    }
}

// MARK: - Private methods

private extension PlaceSettingsRepository {

    /// Names the home and stores the name, unless the home has moved or gone meanwhile.
    func lookUpAddress(of coordinate: GeoCoordinate) {
        guard let addressResolver else { return }
        addressLookup?.cancel()
        addressLookup = Task { [weak self] in
            guard let address = await addressResolver.address(at: coordinate), !Task.isCancelled else { return }
            guard let self, let home = subject.value.home, home.coordinate == coordinate else { return }
            save(PlaceSettings(
                home: HomePlace(coordinate: coordinate, radiusKm: home.radiusKm, address: address),
                currentLocationRadiusKm: subject.value.currentLocationRadiusKm
            ))
        }
    }

    func save(_ settings: PlaceSettings) {
        guard settings != subject.value else { return }
        if let home = settings.home {
            defaults.set(home.coordinate.latitude, forKey: Constants.homeLatitudeKey)
            defaults.set(home.coordinate.longitude, forKey: Constants.homeLongitudeKey)
            defaults.set(home.radiusKm, forKey: Constants.homeRadiusKey)
            defaults.set(home.address?.locality, forKey: Constants.homeLocalityKey)
            defaults.set(home.address?.street, forKey: Constants.homeStreetKey)
        } else {
            [
                Constants.homeLatitudeKey, Constants.homeLongitudeKey, Constants.homeRadiusKey,
                Constants.homeLocalityKey, Constants.homeStreetKey
            ]
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
        let locality = defaults.string(forKey: Constants.homeLocalityKey)
        let street = defaults.string(forKey: Constants.homeStreetKey)
        let address = locality == nil && street == nil ? nil : PlaceAddress(locality: locality, street: street)
        return PlaceSettings(
            home: HomePlace(
                coordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
                radiusKm: homeRadius,
                address: address
            ),
            currentLocationRadiusKm: currentRadius
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let homeLatitudeKey = "homeLatitude"
    static let homeLongitudeKey = "homeLongitude"
    static let homeRadiusKey = "homeRadiusKm"
    static let homeLocalityKey = "homeLocality"
    static let homeStreetKey = "homeStreet"
    static let currentLocationRadiusKey = "currentLocationRadiusKm"
}
