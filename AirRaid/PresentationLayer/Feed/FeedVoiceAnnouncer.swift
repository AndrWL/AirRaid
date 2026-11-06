//
//  FeedVoiceAnnouncer.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation
import UIKit

/// Reads the feed aloud, like a radio of the monitoring channels.
///
/// Rules for a new line:
/// - only while the voice feed is on and the sound mode is "Sound" (vibration and "Off" keep it silent);
/// - nothing older than ``Constants/freshness``: a reconnect replays the night, the voice must not;
/// - not below ``VoiceSettings/minimumPriority``; a threat inside a place's radius is always critical and interrupts;
/// - with "My places", only bubbles in the oblasts of the user's places, country-wide reports and near threats;
/// - endings (all-clears, closed tracks) only when ``VoiceSettings/readsEndings``.
///
/// Without Plus the rules are the defaults (normal priority and up, "My places", normal speed); endings and keeping the
/// screen awake are the user's choice either way.
///
/// - Note: iOS suspends the app soon after the screen locks with nothing playing, so the feed is meant to be listened
///   to with the app open; ``VoiceSettings/keepsScreenAwake`` keeps the screen on meanwhile.
final class FeedVoiceAnnouncer {

    /// The services the announcer only calls, grouped to keep the initializer short.
    struct Dependencies {
        let speechService: SpeechServiceProtocol
        let voiceSettingsService: VoiceSettingsServiceProtocol
        let entitlementService: EntitlementServiceProtocol
        let alertSoundService: AlertSoundServiceProtocol
    }

    // MARK: - Variables

    private let feedRepository: FeedRepositoryProtocol
    private let dependencies: Dependencies
    private let isLiveSubject = CurrentValueSubject<Bool, Never>(false)

    private var settings: VoiceSettings = .default
    private var isPlusActive = false
    private var soundMode: AlertSoundMode = .sound
    private var situation: AirSituation = .empty
    private var places: [WatchedPlace] = []
    private var watchedRegionIDs: Set<String> = []
    private var cancellables: Set<AnyCancellable> = []

    init(
        feedRepository: FeedRepositoryProtocol,
        airSituationRepository: AirSituationRepositoryProtocol,
        watchedPlacesProvider: WatchedPlacesProviding,
        watchedRegionsProvider: WatchedRegionsProviding,
        dependencies: Dependencies
    ) {
        self.feedRepository = feedRepository
        self.dependencies = dependencies
        bind(
            airSituationRepository: airSituationRepository,
            watchedPlacesProvider: watchedPlacesProvider,
            watchedRegionsProvider: watchedRegionsProvider
        )
    }
}

// MARK: - FeedVoiceAnnouncing

extension FeedVoiceAnnouncer: FeedVoiceAnnouncing {

    var isLivePublisher: AnyPublisher<Bool, Never> {
        isLiveSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var isSpeakingPublisher: AnyPublisher<Bool, Never> {
        dependencies.speechService.isSpeakingPublisher
    }

    func setLive(_ isLive: Bool) {
        guard isLive != isLiveSubject.value else { return }
        isLiveSubject.send(isLive)
        updateIdleTimer()
        if isLive {
            dependencies.speechService.speak(Constants.liveOnPhrase, interrupting: true, rate: effectiveSettings.speechRate)
        } else {
            dependencies.speechService.stop()
        }
    }

    func read(_ item: FeedItem) {
        guard let line = item.lines.last else { return }
        dependencies.speechService.speak(
            FeedText.speech(FeedEntry(item: item, line: line)),
            interrupting: true,
            rate: effectiveSettings.speechRate
        )
    }
}

// MARK: - Private methods

private extension FeedVoiceAnnouncer {

    /// The user's settings with Plus, the defaults for what only Plus may change otherwise.
    var effectiveSettings: VoiceSettings {
        guard !isPlusActive else { return settings }
        var effective = VoiceSettings.default
        effective.readsEndings = settings.readsEndings
        effective.keepsScreenAwake = settings.keepsScreenAwake
        return effective
    }

    func bind(
        airSituationRepository: AirSituationRepositoryProtocol,
        watchedPlacesProvider: WatchedPlacesProviding,
        watchedRegionsProvider: WatchedRegionsProviding
    ) {
        feedRepository.entriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.announce(entries)
            }
            .store(in: &cancellables)

        dependencies.voiceSettingsService.settingsPublisher
            .sink { [weak self] settings in
                self?.settings = settings
                self?.updateIdleTimer()
            }
            .store(in: &cancellables)

        dependencies.entitlementService.isPlusActivePublisher
            .sink { [weak self] isActive in
                self?.isPlusActive = isActive
            }
            .store(in: &cancellables)

        dependencies.alertSoundService.modePublisher
            .sink { [weak self] mode in
                self?.soundMode = mode
            }
            .store(in: &cancellables)

        airSituationRepository.situationPublisher
            .sink { [weak self] situation in
                self?.situation = situation
            }
            .store(in: &cancellables)

        watchedPlacesProvider.placesPublisher
            .sink { [weak self] places in
                self?.places = places
            }
            .store(in: &cancellables)

        watchedRegionsProvider.regionIDsPublisher
            .sink { [weak self] regionIDs in
                self?.watchedRegionIDs = regionIDs
            }
            .store(in: &cancellables)
    }

    func announce(_ entries: [FeedEntry]) {
        guard isLiveSubject.value, soundMode == .sound else { return }
        let settings = effectiveSettings
        let now = Date()
        let places = places
        let threats = Dictionary(situation.threats.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })

        for entry in entries where now.timeIntervalSince(entry.line.date) <= Constants.freshness {
            if entry.line.event.isEnding, !settings.readsEndings {
                continue
            }
            var isNear = false
            var isCountryWide = false
            if case .threat(let threat) = entry.item.content {
                isNear = threats[threat.threatID]?.isNear(places) == true
                isCountryWide = threat.isCountryWide
            }
            let priority = isNear ? .critical : entry.item.priority
            guard priority >= settings.minimumPriority else { continue }
            if settings.isOnlyMyPlaces,
               !isNear, !isCountryWide,
               entry.item.regionIDs.isDisjoint(with: watchedRegionIDs) {
                continue
            }
            dependencies.speechService.speak(
                FeedText.speech(entry),
                interrupting: priority == .critical,
                rate: settings.speechRate
            )
        }
    }

    func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = isLiveSubject.value && settings.keepsScreenAwake
    }
}

// MARK: - FeedLineEvent

private extension FeedLineEvent {

    var isEnding: Bool {
        switch self {
        case .threatClosed, .alertEnded: true
        default: false
        }
    }
}

// MARK: - Constants

private enum Constants {
    /// Lines older than this when they arrive are history, not news.
    static let freshness: TimeInterval = 120
    static let liveOnPhrase = "Голосовий ефір увімкнено."
}
