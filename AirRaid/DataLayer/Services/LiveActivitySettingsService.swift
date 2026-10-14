//
//  LiveActivitySettingsService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import ActivityKit
import Combine
import Foundation

/// Keeps the user's Live Activity choice in `UserDefaults` and reads the system's permission from ActivityKit.
final class LiveActivitySettingsService {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let subject: CurrentValueSubject<Bool, Never>

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        let stored = defaults.object(forKey: Constants.isEnabledKey) as? Bool
        self.subject = CurrentValueSubject(stored ?? true)
    }
}

// MARK: - LiveActivitySettingsServiceProtocol

extension LiveActivitySettingsService: LiveActivitySettingsServiceProtocol {

    var isEnabledPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    var isAllowedBySystem: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func setEnabled(_ isEnabled: Bool) {
        guard isEnabled != subject.value else { return }
        defaults.set(isEnabled, forKey: Constants.isEnabledKey)
        subject.send(isEnabled)
    }
}

// MARK: - Constants

private enum Constants {
    static let isEnabledKey = "liveActivityEnabled"
}
