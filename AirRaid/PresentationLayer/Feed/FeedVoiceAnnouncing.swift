//
//  FeedVoiceAnnouncing.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine

/// The voice feed: reads new lines aloud while the user listens, and single bubbles on request.
protocol FeedVoiceAnnouncing {

    /// Whether the voice feed is on. Emits on subscription.
    var isLivePublisher: AnyPublisher<Bool, Never> { get }

    /// Whether something is being said right now. Emits on subscription.
    var isSpeakingPublisher: AnyPublisher<Bool, Never> { get }

    /// Turns the voice feed on or off; off also stops what is being said.
    func setLive(_ isLive: Bool)

    /// Reads the bubble's current state once — available in every sound mode, it is the user's own request.
    func read(_ item: FeedItem)
}
