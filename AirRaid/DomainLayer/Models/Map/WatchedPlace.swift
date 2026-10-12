//
//  WatchedPlace.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// A place the user watches threats around: where they are now, or their home.
nonisolated struct WatchedPlace: Hashable, Sendable {

    let kind: WatchedPlaceKind

    let coordinate: GeoCoordinate

    /// Threats within this distance count as near the place.
    let radiusKm: Double

    /// The places to watch: the current location while it is known, and the home once it is set.
    static func places(
        currentLocation: GeoCoordinate?,
        settings: PlaceSettings
    ) -> [WatchedPlace] {
        var places: [WatchedPlace] = []
        if let currentLocation {
            places.append(WatchedPlace(
                kind: .currentLocation,
                coordinate: currentLocation,
                radiusKm: settings.currentLocationRadiusKm
            ))
        }
        if let home = settings.home {
            places.append(WatchedPlace(kind: .home, coordinate: home.coordinate, radiusKm: home.radiusKm))
        }
        return places
    }
}

/// Which place a ``WatchedPlace`` is.
nonisolated enum WatchedPlaceKind: Hashable, Sendable {

    /// The device's location.
    case currentLocation

    /// The pin the user dropped on the map.
    case home
}
