//
//  VoiceSettingsService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation

/// Keeps ``VoiceSettings`` in `UserDefaults`, one key per field, so a new field later keeps the old ones.
final class VoiceSettingsService {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let subject: CurrentValueSubject<VoiceSettings, Never>

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.subject = CurrentValueSubject(Self.load(from: defaults))
    }
}

// MARK: - VoiceSettingsServiceProtocol

extension VoiceSettingsService: VoiceSettingsServiceProtocol {

    var settingsPublisher: AnyPublisher<VoiceSettings, Never> {
        subject.eraseToAnyPublisher()
    }

    func update(_ settings: VoiceSettings) {
        guard settings != subject.value else { return }
        defaults.set(settings.minimumPriority.rawValue, forKey: Key.minimumPriority)
        defaults.set(settings.isOnlyMyPlaces, forKey: Key.isOnlyMyPlaces)
        defaults.set(settings.readsEndings, forKey: Key.readsEndings)
        defaults.set(settings.speechRate.rawValue, forKey: Key.speechRate)
        defaults.set(settings.keepsScreenAwake, forKey: Key.keepsScreenAwake)
        subject.send(settings)
    }
}

// MARK: - Private methods

private extension VoiceSettingsService {

    static func load(from defaults: UserDefaults) -> VoiceSettings {
        let fallback = VoiceSettings.default
        return VoiceSettings(
            minimumPriority: (defaults.object(forKey: Key.minimumPriority) as? Int).flatMap(FeedPriority.init(rawValue:))
                ?? fallback.minimumPriority,
            isOnlyMyPlaces: defaults.object(forKey: Key.isOnlyMyPlaces) as? Bool ?? fallback.isOnlyMyPlaces,
            readsEndings: defaults.object(forKey: Key.readsEndings) as? Bool ?? fallback.readsEndings,
            speechRate: defaults.string(forKey: Key.speechRate).flatMap(VoiceSpeechRate.init(rawValue:)) ?? fallback.speechRate,
            keepsScreenAwake: defaults.object(forKey: Key.keepsScreenAwake) as? Bool ?? fallback.keepsScreenAwake
        )
    }
}

// MARK: - Constants

private enum Key {
    static let minimumPriority = "voiceMinimumPriority"
    static let isOnlyMyPlaces = "voiceOnlyMyPlaces"
    static let readsEndings = "voiceReadsEndings"
    static let speechRate = "voiceSpeechRate"
    static let keepsScreenAwake = "voiceKeepsScreenAwake"
}
