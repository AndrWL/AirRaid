//
//  NotificationPermissionService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import UserNotifications

/// Reads and asks for the notification permission through `UNUserNotificationCenter`.
struct NotificationPermissionService {

}

// MARK: - NotificationPermissionServiceProtocol

extension NotificationPermissionService: NotificationPermissionServiceProtocol {

    func authorization() async -> NotificationAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return Self.map(settings.authorizationStatus)
    }

    func requestAuthorization() async -> NotificationAuthorization {
        let current = await authorization()
        guard current == .notDetermined else { return current }
        // A failed request leaves the permission as it was; reading it back tells the caller where things stand.
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        return await authorization()
    }
}

// MARK: - Private methods

private extension NotificationPermissionService {

    static func map(_ status: UNAuthorizationStatus) -> NotificationAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .authorized
        @unknown default: .denied
        }
    }
}
