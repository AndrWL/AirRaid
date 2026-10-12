//
//  PlaceSettings.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// The user's watched places as they set them up: the home pin and the radius around each place.
nonisolated struct PlaceSettings: Hashable, Sendable {

    /// The home pin, or `nil` until the user drops one.
    let home: HomePlace?

    /// The radius around the user's current location.
    let currentLocationRadiusKm: Double

    /// The radius a place starts with: a city and its outskirts.
    static let defaultRadiusKm: Double = 25

    /// No home and the default radius.
    static let initial = PlaceSettings(home: nil, currentLocationRadiusKm: defaultRadiusKm)
}

/// The home pin and the radius around it.
nonisolated struct HomePlace: Hashable, Sendable {

    let coordinate: GeoCoordinate

    let radiusKm: Double
}
