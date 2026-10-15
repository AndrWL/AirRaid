//
//  VoiceSettings.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

/// What the voice feed reads aloud and how.
nonisolated struct VoiceSettings: Hashable, Sendable {

    /// Lines of quieter bubbles are skipped.
    var minimumPriority: FeedPriority

    /// Only bubbles in the oblasts of the user's places — or a threat inside a place's radius.
    var isOnlyMyPlaces: Bool

    /// Read the all-clears and closed tracks too, not only what starts.
    var readsEndings: Bool

    var speechRate: VoiceSpeechRate

    /// Keep the screen on while the voice feed plays: iOS stops the app soon after the screen locks in silence.
    var keepsScreenAwake: Bool

    /// What a free user gets and what a subscriber starts with.
    static let `default` = VoiceSettings(
        minimumPriority: .normal,
        isOnlyMyPlaces: true,
        readsEndings: true,
        speechRate: .normal,
        keepsScreenAwake: true
    )
}

/// How fast the voice speaks.
nonisolated enum VoiceSpeechRate: String, CaseIterable, Sendable {
    case slow
    case normal
    case fast
}
