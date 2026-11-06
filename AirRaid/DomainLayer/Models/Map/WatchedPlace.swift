//
//  WatchedPlace.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// A place the user watches threats around: where they are now, their home, or another place they pinned.
nonisolated struct WatchedPlace: Hashable, Sendable, Identifiable {

    /// ``currentLocationID`` for the current location, the saved place's id otherwise.
    let id: String

    let kind: WatchedPlaceKind

    /// The user's name for a custom place, or its locality until it has one; `nil` for the location and the home.
    let name: String?

    let coordinate: GeoCoordinate

    /// Threats within this distance count as near the place.
    let radiusKm: Double

    /// The saved place's address once it is known; `nil` for the current location.
    var address: PlaceAddress?

    static let currentLocationID = "currentLocation"

    /// Whether the point is inside the place's radius.
    func contains(_ point: GeoCoordinate) -> Bool {
        coordinate.distance(to: point) <= radiusKm
    }

    /// The places to watch: the current location while it is known, the home once it is set, and the custom places
    /// while AirRaid Plus is active — kept but paused without it.
    static func places(
        currentLocation: GeoCoordinate?,
        settings: PlaceSettings,
        includesCustomPlaces: Bool
    ) -> [WatchedPlace] {
        var places: [WatchedPlace] = []
        if let currentLocation {
            places.append(WatchedPlace(
                id: currentLocationID,
                kind: .currentLocation,
                name: nil,
                coordinate: currentLocation,
                radiusKm: settings.currentLocationRadiusKm
            ))
        }
        let saved = settings.places.filter { includesCustomPlaces || $0.kind == .home }
        places += saved.prefix(PremiumLimits.plusPlaces).map(WatchedPlace.init)
        return places
    }
}

nonisolated extension WatchedPlace {

    init(_ place: SavedPlace) {
        let kind: WatchedPlaceKind = place.kind == .home ? .home : .custom
        self.init(
            id: place.id.uuidString,
            kind: kind,
            name: kind == .custom ? place.name ?? place.address?.locality : nil,
            coordinate: place.coordinate,
            radiusKm: place.radiusKm,
            address: place.address
        )
    }
}

/// Which place a ``WatchedPlace`` is.
nonisolated enum WatchedPlaceKind: Hashable, Sendable {

    /// The device's location.
    case currentLocation

    /// The pin the user dropped on the map.
    case home

    /// One more pinned place with its own name.
    case custom
}

// MARK: - Threat

nonisolated extension Threat {

    /// Whether the threat's last reported position is inside the radius of any of the places, or, when only its target
    /// is known, whether it is heading into that radius.
    ///
    /// The reported position only, never the forecast: a red pin and a sound must not rest on a guess. An approximate
    /// position counts only when its uncertainty fits the radius: "Kyiv, ±62 km" says nothing about a 10 km circle,
    /// it is the city's centre standing in for somewhere in the region. A report of only "heading for Vyshneve" is about
    /// the place itself when Vyshneve is inside the radius, so it counts by its target (``isHeading(into:)``).
    func isNear(_ places: [WatchedPlace]) -> Bool {
        places.contains(where: isNear)
    }

    /// Whether the threat's last reported position is inside the place's radius, by the rule of ``isNear(_:)``.
    func isNear(_ place: WatchedPlace) -> Bool {
        if isHeading(into: place) {
            return true
        }
        guard let position else { return false }
        switch positionQuality {
        case .confirmed:
            return place.contains(position.coordinate)
        case .approximate:
            return place.contains(position.coordinate) && accuracyKm <= place.radiusKm
        case .targetOnly, .area:
            return false
        }
    }

    /// Whether only the threat's target is known and it lies inside the place's radius: there is no position to
    /// measure a distance from, only where the threat is flying.
    func isHeading(into place: WatchedPlace) -> Bool {
        guard positionQuality != .area, position == nil || positionQuality == .targetOnly, let target else { return false }
        return place.contains(target.coordinate)
    }
}
