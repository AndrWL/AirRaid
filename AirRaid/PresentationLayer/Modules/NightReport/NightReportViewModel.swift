//
//  NightReportViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation

/// The view model of the night report: the feed and the user's oblasts, summed up for the last night.
@Observable
final class NightReportViewModel: BaseViewModel {

    // MARK: - Variables

    private(set) var content: NightReportContent?
    private(set) var isSpeaking = false

    @ObservationIgnored
    private let feedRepository: FeedRepositoryProtocol

    @ObservationIgnored
    private let watchedRegionsProvider: WatchedRegionsProviding

    @ObservationIgnored
    private let speechService: SpeechServiceProtocol

    @ObservationIgnored
    private let voiceSettingsService: VoiceSettingsServiceProtocol

    @ObservationIgnored
    private var speechRate: VoiceSpeechRate = .normal

    init(
        feedRepository: FeedRepositoryProtocol,
        watchedRegionsProvider: WatchedRegionsProviding,
        speechService: SpeechServiceProtocol,
        voiceSettingsService: VoiceSettingsServiceProtocol
    ) {
        self.feedRepository = feedRepository
        self.watchedRegionsProvider = watchedRegionsProvider
        self.speechService = speechService
        self.voiceSettingsService = voiceSettingsService
        super.init()
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        feedRepository.itemsPublisher
            .combineLatest(watchedRegionsProvider.regionIDsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items, regionIDs in
                self?.content = NightReportContent.make(items: items, regionIDs: regionIDs, now: .now)
            }
            .store(in: &cancellables)

        speechService.isSpeakingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSpeaking in
                self?.isSpeaking = isSpeaking
            }
            .store(in: &cancellables)

        voiceSettingsService.settingsPublisher
            .sink { [weak self] settings in
                self?.speechRate = settings.speechRate
            }
            .store(in: &cancellables)
    }
}

// MARK: - NightReportViewModelProtocol

extension NightReportViewModel: NightReportViewModelProtocol {

    func didTapListen() {
        guard !isSpeaking else {
            speechService.stop()
            return
        }
        guard let content else { return }
        speechService.speak(content.spokenText, interrupting: true, rate: speechRate)
    }
}

// MARK: - NightReportContent

private extension NightReportContent {

    /// The report as a few sentences, the way a person would tell it.
    var spokenText: String {
        var sentences = ["\(title)."]
        if !hasPlaces {
            sentences.append("Місця не позначено, тож лише загальна картина.")
        } else if isQuiet {
            sentences.append("Біля ваших місць було тихо.")
        } else {
            if alertDuration > 0 {
                sentences.append("Тривога у вашій області тривала \(FeedText.spokenDuration(alertDuration)).")
            }
            for threat in nearbyThreats {
                sentences.append("\(threat.title): \(threat.count).")
            }
        }
        let targets = FeedText.plural(countryThreatCount, one: "ціль", few: "цілі", many: "цілей")
        sentences.append("Усього по країні моніторинг бачив \(countryThreatCount) \(targets).")
        return sentences.joined(separator: " ")
    }
}
