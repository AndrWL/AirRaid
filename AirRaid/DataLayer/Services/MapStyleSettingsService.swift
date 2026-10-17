//
//  MapStyleSettingsService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 17.10.2026.
//

import Combine
import Foundation

/// Keeps the user's map style in `UserDefaults`; follows the system's appearance until the user picks one.
final class MapStyleSettingsService {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let subject: CurrentValueSubject<MapStylePreference, Never>

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Constants.preferenceKey).flatMap(MapStylePreference.init(rawValue:))
        self.subject = CurrentValueSubject(stored ?? .system)
    }
}

// MARK: - MapStyleSettingsServiceProtocol

extension MapStyleSettingsService: MapStyleSettingsServiceProtocol {

    var preferencePublisher: AnyPublisher<MapStylePreference, Never> {
        subject.eraseToAnyPublisher()
    }

    func setPreference(_ preference: MapStylePreference) {
        guard preference != subject.value else { return }
        defaults.set(preference.rawValue, forKey: Constants.preferenceKey)
        subject.send(preference)
    }
}

// MARK: - Constants

private enum Constants {
    static let preferenceKey = "mapStylePreference"
}
