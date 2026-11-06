//
//  VoiceSettingsProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Defines the state of the voice feed's settings.
protocol VoiceSettingsViewModelProtocol: BaseViewModelProtocol {

    var settings: VoiceSettings { get }

    /// The rules (priority, places, speed) are Plus; without it they show the defaults, locked.
    var isPlusActive: Bool { get }

    /// The sound mode is not "Sound", so the voice feed stays silent.
    var isMutedBySoundMode: Bool { get }

    var priorityOptions: [FeedPriority] { get }

    var rateOptions: [VoiceSpeechRate] { get }

    func didSelectMinimumPriority(_ priority: FeedPriority)

    func didToggleOnlyMyPlaces(_ isOn: Bool)

    func didToggleReadsEndings(_ isOn: Bool)

    func didSelectRate(_ rate: VoiceSpeechRate)

    func didToggleKeepsScreenAwake(_ isOn: Bool)

    /// Reads a sample phrase at the selected speed.
    func didTapSample()

    func didTapUnlock()
}

/// Defines the routing capabilities of the voice settings screen.
protocol VoiceSettingsRouterProtocol: BaseRouterProtocol, SheetPresenting where SheetRoute == VoiceSettingsSheetRoute { }

/// Defines the sheets of the voice settings screen.
enum VoiceSettingsSheetRoute: Identifiable {

    case paywall

    var id: Self { self }
}
