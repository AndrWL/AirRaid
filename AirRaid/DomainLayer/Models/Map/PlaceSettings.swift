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

    /// The radii to pick from: from a district of a city to a whole region around it.
    static let radiusOptions: [Double] = [5, 10, 25, 50, 100]

    /// No home and the default radius.
    static let initial = PlaceSettings(home: nil, currentLocationRadiusKm: defaultRadiusKm)
}

/// The home pin and the radius around it.
nonisolated struct HomePlace: Hashable, Sendable {

    let coordinate: GeoCoordinate

    let radiusKm: Double

    /// Where the home is, once the geocoder has named it; `nil` until then or when it could not.
    let address: PlaceAddress?

    init(
        coordinate: GeoCoordinate,
        radiusKm: Double,
        address: PlaceAddress? = nil
    ) {
        self.coordinate = coordinate
        self.radiusKm = radiusKm
        self.address = address
    }
}
