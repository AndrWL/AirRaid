//
//  SpeechServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine

/// Speaks Ukrainian text with the device's voice, one phrase after another.
protocol SpeechServiceProtocol {

    /// Whether a phrase is being spoken or waits in the queue. Emits on subscription.
    var isSpeakingPublisher: AnyPublisher<Bool, Never> { get }

    /// Queues the phrase.
    ///
    /// - Parameters:
    ///   - text: Written for the ear: no emoji, no abbreviations.
    ///   - interrupting: Stop what is being said and clear the queue first — for a critical threat.
    ///   - rate: How fast to speak.
    func speak(
        _ text: String,
        interrupting: Bool,
        rate: VoiceSpeechRate
    )

    /// Stops at once and clears the queue.
    func stop()
}
