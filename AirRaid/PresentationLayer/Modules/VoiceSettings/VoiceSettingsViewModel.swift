//
//  VoiceSettingsViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation

/// The view model of the voice feed's settings.
@Observable
final class VoiceSettingsViewModel<Router: VoiceSettingsRouterProtocol>: BaseViewModel {

    // MARK: - Variables

    let priorityOptions: [FeedPriority] = [.low, .normal, .high, .critical]
    let rateOptions = VoiceSpeechRate.allCases
    private(set) var settings: VoiceSettings = .default
    private(set) var isPlusActive = false
    private(set) var isMutedBySoundMode = false

    @ObservationIgnored
    private let router: Router

    @ObservationIgnored
    private let voiceSettingsService: VoiceSettingsServiceProtocol

    @ObservationIgnored
    private let entitlementService: EntitlementServiceProtocol

    @ObservationIgnored
    private let alertSoundService: AlertSoundServiceProtocol

    @ObservationIgnored
    private let speechService: SpeechServiceProtocol

    init(
        router: Router,
        voiceSettingsService: VoiceSettingsServiceProtocol,
        entitlementService: EntitlementServiceProtocol,
        alertSoundService: AlertSoundServiceProtocol,
        speechService: SpeechServiceProtocol
    ) {
        self.router = router
        self.voiceSettingsService = voiceSettingsService
        self.entitlementService = entitlementService
        self.alertSoundService = alertSoundService
        self.speechService = speechService
        super.init()
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        voiceSettingsService.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)

        entitlementService.isPlusActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.isPlusActive = isActive
            }
            .store(in: &cancellables)

        alertSoundService.modePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.isMutedBySoundMode = mode != .sound
            }
            .store(in: &cancellables)
    }
}

// MARK: - VoiceSettingsViewModelProtocol

extension VoiceSettingsViewModel: VoiceSettingsViewModelProtocol {

    func didSelectMinimumPriority(_ priority: FeedPriority) {
        guard isPlusActive else { return didTapUnlock() }
        update { $0.minimumPriority = priority }
    }

    func didToggleOnlyMyPlaces(_ isOn: Bool) {
        guard isPlusActive else { return didTapUnlock() }
        update { $0.isOnlyMyPlaces = isOn }
    }

    func didToggleReadsEndings(_ isOn: Bool) {
        update { $0.readsEndings = isOn }
    }

    func didSelectRate(_ rate: VoiceSpeechRate) {
        guard isPlusActive else { return didTapUnlock() }
        update { $0.speechRate = rate }
        didTapSample()
    }

    func didToggleKeepsScreenAwake(_ isOn: Bool) {
        update { $0.keepsScreenAwake = isOn }
    }

    func didTapSample() {
        let rate = isPlusActive ? settings.speechRate : VoiceSettings.default.speechRate
        speechService.speak(Constants.samplePhrase, interrupting: true, rate: rate)
    }

    func didTapUnlock() {
        router.presentSheet(.paywall)
    }
}

// MARK: - Private methods

private extension VoiceSettingsViewModel {

    /// Shown at once; the service's echo a run loop later carries the same value.
    func update(_ change: (inout VoiceSettings) -> Void) {
        var settings = settings
        change(&settings)
        self.settings = settings
        voiceSettingsService.update(settings)
    }
}

// MARK: - Constants

private enum Constants {
    static let samplePhrase = "Шахед, 3 цілі. Помічено: Ніжин. Ймовірно курсом на Бровари."
}
