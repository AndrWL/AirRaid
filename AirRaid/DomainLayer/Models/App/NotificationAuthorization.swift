//
//  NotificationAuthorization.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// Whether the app may show notifications, as far as the settings need to know.
nonisolated enum NotificationAuthorization: Sendable {

    /// The user has not been asked yet.
    case notDetermined

    /// Denied; only the Settings app can change it.
    case denied

    /// Allowed, including provisionally (delivered quietly to the Notification Center).
    case authorized
}
