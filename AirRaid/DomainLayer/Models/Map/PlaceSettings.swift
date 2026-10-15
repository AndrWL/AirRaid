//
//  PlaceSettings.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// The user's watched places as they set them up: the saved places (the home and, with AirRaid Плюс, more) and the
/// radius around the current location.
nonisolated struct PlaceSettings: Hashable, Sendable {

    /// The home first when there is one, then the other places in the order they were added.
    let places: [SavedPlace]

    /// The radius around the user's current location.
    let currentLocationRadiusKm: Double

    /// The radius a place starts with: a city and its outskirts.
    static let defaultRadiusKm: Double = 25

    /// The radii to pick from: from a district of a city to a whole region around it.
    static let radiusOptions: [Double] = [5, 10, 25, 50, 100]

    /// No places and the default radius.
    static let initial = PlaceSettings(places: [], currentLocationRadiusKm: defaultRadiusKm)

    /// The home pin, or `nil` until the user drops one.
    var home: SavedPlace? {
        places.first { $0.kind == .home }
    }

    /// The places other than the home: parents, work, school.
    var customPlaces: [SavedPlace] {
        places.filter { $0.kind == .custom }
    }

    func place(id: SavedPlace.ID) -> SavedPlace? {
        places.first { $0.id == id }
    }

    /// The same settings with the place replaced, or added at the end when it is new; the home always stays first.
    func replacing(_ place: SavedPlace) -> PlaceSettings {
        var places = places
        if let index = places.firstIndex(where: { $0.id == place.id }) {
            places[index] = place
        } else if place.kind == .home {
            places.insert(place, at: 0)
        } else {
            places.append(place)
        }
        return PlaceSettings(places: places, currentLocationRadiusKm: currentLocationRadiusKm)
    }

    func removing(_ id: SavedPlace.ID) -> PlaceSettings {
        PlaceSettings(places: places.filter { $0.id != id }, currentLocationRadiusKm: currentLocationRadiusKm)
    }

    func withCurrentLocationRadius(_ radiusKm: Double) -> PlaceSettings {
        PlaceSettings(places: places, currentLocationRadiusKm: radiusKm)
    }
}

/// A place the user pinned on the map: the home, or another one with its own name.
nonisolated struct SavedPlace: Hashable, Sendable, Identifiable {

    let id: UUID

    let kind: SavedPlaceKind

    /// The user's name for a custom place; `nil` for the home, or until the user names it.
    let name: String?

    let coordinate: GeoCoordinate

    let radiusKm: Double

    /// Where the place is, once the geocoder has named it; `nil` until then or when it could not.
    let address: PlaceAddress?

    init(
        id: UUID = UUID(),
        kind: SavedPlaceKind,
        name: String? = nil,
        coordinate: GeoCoordinate,
        radiusKm: Double,
        address: PlaceAddress? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.coordinate = coordinate
        self.radiusKm = radiusKm
        self.address = address
    }

    func with(
        name: String?? = nil,
        coordinate: GeoCoordinate? = nil,
        radiusKm: Double? = nil,
        address: PlaceAddress?? = nil
    ) -> SavedPlace {
        SavedPlace(
            id: id,
            kind: kind,
            name: name ?? self.name,
            coordinate: coordinate ?? self.coordinate,
            radiusKm: radiusKm ?? self.radiusKm,
            address: address ?? self.address
        )
    }
}

/// Which kind of place a ``SavedPlace`` is.
nonisolated enum SavedPlaceKind: String, Hashable, Sendable {

    /// The one place the widgets, the Live Activity and the free plan follow.
    case home

    /// One more place, with AirRaid Плюс.
    case custom
}
