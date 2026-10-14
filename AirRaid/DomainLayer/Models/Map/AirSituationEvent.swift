//
//  AirSituationEvent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// One change of the air situation, as it happened — what the feed is built from.
///
/// ``AirSituation`` says only what is true now; the feed needs to know *how* it changed: that a threat closed as a
/// duplicate and not because it vanished, that an alert ended rather than being replaced.
nonisolated enum AirSituationEvent: Hashable, Sendable {

    /// A threat appeared or got a new report. `previous` is the value it replaces, `nil` for a new one.
    case threatUpdated(Threat, previous: Threat?)

    /// A threat is gone. `threat` is its last known value.
    case threatClosed(Threat, reason: ThreatCloseReason, at: Date)

    /// An official alert was declared or replaced. `previous` is the value it replaces, `nil` for a new one.
    case alertStarted(RegionAlert, previous: RegionAlert?)

    /// An official alert ended. `alert` is its last known value.
    case alertEnded(RegionAlert, at: Date)
}

/// Why a threat left the situation.
nonisolated enum ThreatCloseReason: Hashable, Sendable {

    /// Timed out or the channels gave the all-clear.
    case ended

    /// The channel deleted the report.
    case cancelled

    /// A duplicate of another threat, which carries on under `survivorID`.
    case merged(survivorID: String?)

    /// The threat was missing from a fresh snapshot, so nothing is known about how it left.
    case unknown
}
