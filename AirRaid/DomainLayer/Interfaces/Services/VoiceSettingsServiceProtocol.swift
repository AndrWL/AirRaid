//
//  VoiceSettingsServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine

/// Keeps the user's ``VoiceSettings`` across launches.
protocol VoiceSettingsServiceProtocol {

    /// Emits on subscription and after every change.
    var settingsPublisher: AnyPublisher<VoiceSettings, Never> { get }

    func update(_ settings: VoiceSettings)
}
