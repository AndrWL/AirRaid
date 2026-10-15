//
//  FeedItem.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// One bubble of the feed: a threat's track or a group of official alerts, with the lines it gathered over its life.
///
/// A bubble is edited, not repeated: a new report about the same threat adds a line to its bubble instead of a new
/// message, the way the best monitoring channels edit their posts.
nonisolated struct FeedItem: Identifiable, Hashable, Sendable {

    /// `threat:<event id>` or `alert:<oblast>:<kind>:<start>` — stable across launches.
    let id: String

    /// When the bubble appeared: the threat's first report or the first alert of the group.
    let createdAt: Date

    /// The latest change; the bubble counts as unread after it.
    var updatedAt: Date

    /// Still going: the threat is tracked, or an alert of the group has not ended.
    var isActive: Bool

    var priority: FeedPriority

    /// Every oblast the bubble touched, for the «Мої місця» filter.
    var regionIDs: Set<String>

    /// What happened, oldest first; at most ``FeedItem/maxLines``, the oldest dropped first.
    var lines: [FeedLine]

    /// How many lines were dropped from the start.
    var droppedLineCount: Int

    var content: FeedContent

    /// More lines than this would turn one bubble into a channel of its own.
    static let maxLines = 20
}

// MARK: - Mutating methods

nonisolated extension FeedItem {

    /// Adds the line, dropping the oldest past ``maxLines``, and moves ``updatedAt``.
    mutating func append(_ line: FeedLine) {
        lines.append(line)
        if lines.count > Self.maxLines {
            lines.removeFirst()
            droppedLineCount += 1
        }
        updatedAt = max(updatedAt, line.date)
    }
}

/// What a bubble is about.
nonisolated enum FeedContent: Hashable, Sendable {

    case threat(FeedThreat)

    case alert(FeedAlert)
}

/// The last known state of a threat, as much of it as the feed shows; the live ``Threat`` is looked up by ``threatID``.
nonisolated struct FeedThreat: Hashable, Sendable {

    let threatID: String

    var kind: ThreatKind

    var type: ThreatType?

    var count: Int?

    var level: ThreatLevel

    var regionID: String

    var regionName: String

    /// Where it was last reported, when known.
    var positionName: String?

    /// Where it flies, when known.
    var targetName: String?

    var isCountryWide: Bool
}

/// Official alerts of one kind in one oblast, declared close together — one bubble, like a channel post listing them.
nonisolated struct FeedAlert: Hashable, Sendable {

    let kind: RegionAlertKind

    /// The highest level among the places.
    var level: RegionAlertLevel?

    let regionID: String

    var places: [FeedAlertPlace]
}

/// One place of a ``FeedAlert``.
nonisolated struct FeedAlertPlace: Hashable, Sendable {

    /// The alert's id in alerts.in.ua — stable for the place, reused by its next alert.
    let alertID: String

    let name: String

    let scope: RegionAlertScope

    let startedAt: Date

    /// `nil` while the alert lasts.
    var endedAt: Date?
}
