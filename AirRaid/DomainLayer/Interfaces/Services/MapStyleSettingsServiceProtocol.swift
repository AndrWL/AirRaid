//
//  MapStyleSettingsServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 17.10.2026.
//

import Combine

/// Keeps the user's choice of the base map's look.
protocol MapStyleSettingsServiceProtocol {

    /// Emits the current preference on subscription and every change after it.
    var preferencePublisher: AnyPublisher<MapStylePreference, Never> { get }

    /// Keeps the preference across launches.
    func setPreference(_ preference: MapStylePreference)
}
