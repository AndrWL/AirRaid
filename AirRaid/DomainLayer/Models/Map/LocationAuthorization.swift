//
//  LocationAuthorization.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// Whether the app may read the user's location, as far as the map needs to know.
nonisolated enum LocationAuthorization: Sendable {

    /// The user has not been asked yet.
    case notDetermined

    /// Denied, or restricted by the device's settings; only the Settings app can change it.
    case denied

    /// Allowed while the app is in use.
    case authorized
}
