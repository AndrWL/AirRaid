//
//  FeedLine.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// One significant change inside a bubble — never a plain move, which only updates the bubble's header.
nonisolated struct FeedLine: Hashable, Sendable {

    let date: Date

    let event: FeedLineEvent
}

/// What a ``FeedLine`` says. The text is built by the presentation layer, separately for the screen and for the voice.
nonisolated enum FeedLineEvent: Hashable, Sendable {

    // MARK: - Threats

    /// A new track: where it was spotted and where it flies, as far as known.
    case threatAppeared(regionName: String, positionName: String?, targetName: String?)

    /// The type became known or changed: an unknown target turned out to be a drone, a Shahed a jet one.
    case threatRefined(kind: ThreatKind, type: ThreatType?)

    case threatCountChanged(Int)

    /// More channels confirmed it.
    case threatConfirmed(level: ThreatLevel, sourceCount: Int)

    /// It crossed into another oblast.
    case threatCrossedRegion(regionName: String)

    /// It flies to a different place now.
    case threatCourseChanged(targetName: String)

    case threatClosed(ThreatCloseReason)

    // MARK: - Official alerts

    case alertStarted(placeName: String)

    case alertLevelChanged(RegionAlertLevel)

    case alertEnded(placeName: String, duration: TimeInterval)
}

// MARK: - Computed properties

nonisolated extension FeedLineEvent {

    /// Lines of the same family are throttled together: a track that changes course every minute gets one line.
    var family: Int {
        switch self {
        case .threatAppeared: 0
        case .threatRefined: 1
        case .threatCountChanged: 2
        case .threatConfirmed: 3
        case .threatCrossedRegion: 4
        case .threatCourseChanged: 5
        case .threatClosed: 6
        case .alertStarted: 7
        case .alertLevelChanged: 8
        case .alertEnded: 9
        }
    }
}
