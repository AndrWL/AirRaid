//
//  FeedEntry.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

/// A line just added to the feed, with its bubble as it is after the change — what the voice reads.
nonisolated struct FeedEntry: Hashable, Sendable {

    let item: FeedItem

    let line: FeedLine
}
