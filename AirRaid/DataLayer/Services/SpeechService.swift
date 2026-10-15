//
//  SpeechService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import AVFoundation
import Combine
import OSLog

/// Speaks with the system's Ukrainian voice — the best one installed (an Enhanced or Premium voice if the user
/// downloaded it in Settings › Accessibility › Spoken Content).
///
/// The audio session is active only while something is said, and lowers other audio (music, a podcast) meanwhile
/// instead of stopping it. Works offline: the voice is on the device.
final class SpeechService: NSObject {

    // MARK: - Variables

    private let synthesizer = AVSpeechSynthesizer()
    private let isSpeakingSubject = CurrentValueSubject<Bool, Never>(false)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)
    private lazy var voice: AVSpeechSynthesisVoice? = Self.bestVoice()

    override init() {
        super.init()
        synthesizer.delegate = self
    }
}

// MARK: - SpeechServiceProtocol

extension SpeechService: SpeechServiceProtocol {

    var isSpeakingPublisher: AnyPublisher<Bool, Never> {
        isSpeakingSubject.removeDuplicates().eraseToAnyPublisher()
    }

    func speak(
        _ text: String,
        interrupting: Bool,
        rate: VoiceSpeechRate
    ) {
        if interrupting {
            synthesizer.stopSpeaking(at: .immediate)
        }
        activateSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate.utteranceRate
        utterance.postUtteranceDelay = Constants.pauseBetweenPhrases
        isSpeakingSubject.send(true)
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        finishIfIdle()
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finishIfIdle()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finishIfIdle()
        }
    }
}

// MARK: - Private methods

private extension SpeechService {

    func activateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try session.setActive(true)
        } catch {
            logger.error("Failed to activate the audio session: \(String(describing: error), privacy: .public)")
        }
    }

    /// Gives the audio back to other apps once the queue is empty.
    func finishIfIdle() {
        guard !synthesizer.isSpeaking else { return }
        isSpeakingSubject.send(false)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.debug("Failed to deactivate the audio session: \(String(describing: error), privacy: .public)")
        }
    }

    /// Premium over Enhanced over the default; `nil` falls back to the system's choice for the language.
    static func bestVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == Constants.language }
        return voices.max { $0.quality.rawValue < $1.quality.rawValue } ?? AVSpeechSynthesisVoice(language: Constants.language)
    }
}

// MARK: - VoiceSpeechRate

private extension VoiceSpeechRate {

    var utteranceRate: Float {
        let normal = AVSpeechUtteranceDefaultSpeechRate
        switch self {
        case .slow: return normal * 0.85
        case .normal: return normal
        case .fast: return min(normal * 1.2, AVSpeechUtteranceMaximumSpeechRate)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Speech"
    static let language = "uk-UA"
    static let pauseBetweenPhrases: TimeInterval = 0.4
}
