//
//  PlaceSettingsRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation
import OSLog

/// Keeps the place settings in `UserDefaults`, on the device only: the places are where the user lives and works.
///
/// The places are one JSON list. A home saved by an older build, as separate keys, moves into the list on first load.
/// A place's address is looked up once, when it is set or moved (or for a place saved before addresses existed), and
/// stored with it.
final class PlaceSettingsRepository {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let addressResolver: PlaceAddressResolving?
    private let subject: CurrentValueSubject<PlaceSettings, Never>
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)
    private var addressLookups: [SavedPlace.ID: Task<Void, Never>] = [:]

    init(
        defaults: UserDefaults = .standard,
        addressResolver: PlaceAddressResolving? = nil
    ) {
        self.defaults = defaults
        self.addressResolver = addressResolver
        Self.migrateLegacyHome(in: defaults)
        self.subject = CurrentValueSubject(Self.load(from: defaults))
        for place in subject.value.places where place.address == nil {
            lookUpAddress(of: place)
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
        let home = current.home.map { $0.with(coordinate: coordinate, address: .some(nil)) }
            ?? SavedPlace(kind: .home, coordinate: coordinate, radiusKm: PlaceSettings.defaultRadiusKm)
        save(current.replacing(home))
        lookUpAddress(of: home)
    }

    @discardableResult
    func addPlace(at coordinate: GeoCoordinate, name: String?) -> SavedPlace.ID {
        let place = SavedPlace(
            kind: .custom,
            name: Self.normalized(name),
            coordinate: coordinate,
            radiusKm: PlaceSettings.defaultRadiusKm
        )
        save(subject.value.replacing(place))
        lookUpAddress(of: place)
        return place.id
    }

    func movePlace(_ id: SavedPlace.ID, to coordinate: GeoCoordinate) {
        guard let place = subject.value.place(id: id) else { return }
        let moved = place.with(coordinate: coordinate, address: .some(nil))
        save(subject.value.replacing(moved))
        lookUpAddress(of: moved)
    }

    func renamePlace(_ id: SavedPlace.ID, to name: String?) {
        guard let place = subject.value.place(id: id), place.kind == .custom else { return }
        save(subject.value.replacing(place.with(name: .some(Self.normalized(name)))))
    }

    func setRadius(_ radiusKm: Double, forPlace id: SavedPlace.ID) {
        guard let place = subject.value.place(id: id) else { return }
        save(subject.value.replacing(place.with(radiusKm: radiusKm)))
    }

    func setCurrentLocationRadius(_ radiusKm: Double) {
        save(subject.value.withCurrentLocationRadius(radiusKm))
    }

    func removePlace(_ id: SavedPlace.ID) {
        addressLookups.removeValue(forKey: id)?.cancel()
        save(subject.value.removing(id))
    }
}

// MARK: - Private methods

private extension PlaceSettingsRepository {

    /// Names the place and stores the name, unless the place has moved or gone meanwhile.
    func lookUpAddress(of place: SavedPlace) {
        guard let addressResolver else { return }
        let id = place.id
        let coordinate = place.coordinate
        addressLookups[id]?.cancel()
        addressLookups[id] = Task { [weak self] in
            guard let address = await addressResolver.address(at: coordinate), !Task.isCancelled else { return }
            guard let self, let current = subject.value.place(id: id), current.coordinate == coordinate else { return }
            save(subject.value.replacing(current.with(address: .some(address))))
        }
    }

    func save(_ settings: PlaceSettings) {
        guard settings != subject.value else { return }
        do {
            let data = try JSONEncoder().encode(settings.places.map(SavedPlaceEntityMapper.map))
            defaults.set(data, forKey: Constants.placesKey)
        } catch {
            logger.error("Failed to encode places: \(String(describing: error), privacy: .public)")
        }
        defaults.set(settings.currentLocationRadiusKm, forKey: Constants.currentLocationRadiusKey)
        subject.send(settings)
    }

    /// A blank name is no name: the place goes by its locality.
    static func normalized(_ name: String?) -> String? {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    static func load(from defaults: UserDefaults) -> PlaceSettings {
        let currentRadius = defaults.object(forKey: Constants.currentLocationRadiusKey) as? Double
            ?? PlaceSettings.defaultRadiusKm
        let entities = defaults.data(forKey: Constants.placesKey)
            .flatMap { try? JSONDecoder().decode([SavedPlaceEntity].self, from: $0) } ?? []
        let places = entities.compactMap(SavedPlaceEntityMapper.map)
        // The home first, whatever order an older list was written in.
        let ordered = places.filter { $0.kind == .home }.prefix(1) + places.filter { $0.kind == .custom }
        return PlaceSettings(places: Array(ordered), currentLocationRadiusKm: currentRadius)
    }

    /// Moves a home stored by builds before the list — separate coordinate, radius and address keys — into the list,
    /// then drops the old keys. Runs once: with the list in place, there is nothing to move.
    static func migrateLegacyHome(in defaults: UserDefaults) {
        guard defaults.object(forKey: Constants.placesKey) == nil else { return }
        defer { Constants.legacyHomeKeys.forEach(defaults.removeObject) }
        var entities: [SavedPlaceEntity] = []
        if
            let latitude = defaults.object(forKey: Constants.legacyHomeLatitudeKey) as? Double,
            let longitude = defaults.object(forKey: Constants.legacyHomeLongitudeKey) as? Double {
            entities.append(SavedPlaceEntity(
                id: UUID().uuidString,
                kind: SavedPlaceKind.home.rawValue,
                name: nil,
                latitude: latitude,
                longitude: longitude,
                radiusKm: defaults.object(forKey: Constants.legacyHomeRadiusKey) as? Double ?? PlaceSettings.defaultRadiusKm,
                locality: defaults.string(forKey: Constants.legacyHomeLocalityKey),
                street: defaults.string(forKey: Constants.legacyHomeStreetKey)
            ))
        }
        if let data = try? JSONEncoder().encode(entities) {
            defaults.set(data, forKey: Constants.placesKey)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "PlaceSettings"
    static let placesKey = "savedPlaces"
    static let currentLocationRadiusKey = "currentLocationRadiusKm"
    static let legacyHomeLatitudeKey = "homeLatitude"
    static let legacyHomeLongitudeKey = "homeLongitude"
    static let legacyHomeRadiusKey = "homeRadiusKm"
    static let legacyHomeLocalityKey = "homeLocality"
    static let legacyHomeStreetKey = "homeStreet"
    static let legacyHomeKeys = [
        legacyHomeLatitudeKey, legacyHomeLongitudeKey, legacyHomeRadiusKey, legacyHomeLocalityKey, legacyHomeStreetKey
    ]
}
