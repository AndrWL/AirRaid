//
//  NotificationPermissionServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// Reads and asks for the permission to show notifications.
protocol NotificationPermissionServiceProtocol {

    /// The current permission. The user can change it in the Settings app at any time, so read it again on return.
    func authorization() async -> NotificationAuthorization

    /// Shows the system prompt if the user was never asked; otherwise returns the current permission at once.
    func requestAuthorization() async -> NotificationAuthorization
}
