//
//  FeedPriority.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

/// How loud a bubble is: its colour, whether it is pinned, whether the voice reads it and may interrupt.
///
/// Ordered from quiet to loud, so a "not below" setting is a plain comparison.
nonisolated enum FeedPriority: Int, CaseIterable, Comparable, Sendable {

    /// Unconfirmed reports, reconnaissance drones, all-clears of ended tracks.
    case low

    /// Drones, official air raid alerts.
    case normal

    /// Missiles, guided bombs, aircraft, shelling alerts.
    case high

    /// Ballistic missiles, country-wide reports, chemical and nuclear alerts — and a threat inside the user's radius.
    case critical

    static func < (lhs: FeedPriority, rhs: FeedPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
