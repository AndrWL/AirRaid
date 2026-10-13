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

    /// The home's address once it is known; `nil` for the current location.
    var address: PlaceAddress?

    /// Whether the point is inside the place's radius.
    func contains(_ point: GeoCoordinate) -> Bool {
        coordinate.distance(to: point) <= radiusKm
    }

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
            places.append(WatchedPlace(
                kind: .home,
                coordinate: home.coordinate,
                radiusKm: home.radiusKm,
                address: home.address
            ))
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

// MARK: - Threat

nonisolated extension Threat {

    /// Whether the threat's last reported position is inside the radius of any of the places.
    ///
    /// The reported position only, never the forecast: a red pin and a sound must not rest on a guess. An approximate
    /// position counts only when its uncertainty fits the radius: «Київ, ±62 km» says nothing about a 10 km circle,
    /// it is the city's centre standing in for somewhere in the region.
    func isNear(_ places: [WatchedPlace]) -> Bool {
        guard let position else { return false }
        switch positionQuality {
        case .confirmed:
            return places.contains { $0.contains(position.coordinate) }
        case .approximate:
            return places.contains { $0.contains(position.coordinate) && accuracyKm <= $0.radiusKm }
        case .targetOnly, .area:
            return false
        }
    }
}
