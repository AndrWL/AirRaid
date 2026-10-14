//
//  FeedRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation

/// The feed: the air situation's history as bubbles, kept on the device across launches.
protocol FeedRepositoryProtocol {

    /// Every kept bubble, oldest first, like a chat; emits on subscription and after every change.
    var itemsPublisher: AnyPublisher<[FeedItem], Never> { get }

    /// The lines as they are added, live only — nothing on subscription, nothing restored from disk.
    var entriesPublisher: AnyPublisher<[FeedEntry], Never> { get }

    /// The moment up to which the user has seen the feed; `nil` before the first visit. Emits on subscription.
    var lastReadAtPublisher: AnyPublisher<Date?, Never> { get }

    /// Starts following the air situation. Idempotent; runs for the rest of the session.
    func start()

    /// Remembers that everything up to the date has been seen.
    func markRead(upTo date: Date)
}
