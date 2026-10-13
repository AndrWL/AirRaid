//
//  PlaceSettingsRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine

/// Keeps the home pin and the radius around each watched place.
protocol PlaceSettingsRepositoryProtocol {

    /// Emits the current settings on subscription and every change after it.
    var settingsPublisher: AnyPublisher<PlaceSettings, Never> { get }

    /// Drops the home pin here, keeping its radius if it was set before.
    func setHome(at coordinate: GeoCoordinate)

    func removeHome()

    /// Sets the radius around the place; does nothing for a home that is not set.
    func setRadius(_ radiusKm: Double, for kind: WatchedPlaceKind)
}
