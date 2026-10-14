//
//  LiveActivitySettingsServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine

/// Whether the air raid Live Activity (the lock screen and the Dynamic Island) may run, as the user chose in the
/// settings, and whether iOS allows it at all.
protocol LiveActivitySettingsServiceProtocol {

    /// Emits the user's choice on subscription and every change after it; on by default.
    var isEnabledPublisher: AnyPublisher<Bool, Never> { get }

    /// Whether Live Activities are allowed for the app in the Settings app; read anew on every call.
    var isAllowedBySystem: Bool { get }

    /// Keeps the choice across launches.
    func setEnabled(_ isEnabled: Bool)
}
