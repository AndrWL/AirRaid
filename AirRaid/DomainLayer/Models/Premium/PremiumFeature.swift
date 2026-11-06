//
//  PremiumFeature.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// What AirRaid Plus adds. Convenience only: alerts, threats, the live feed and warnings near the home stay free.
///
/// Every check goes through ``EntitlementServiceProtocol/isPlusActivePublisher`` and this list, never a scattered flag,
/// so moving a feature across the line is a change in one place.
nonisolated enum PremiumFeature: CaseIterable, Sendable {

    /// Places past the home, up to ``PremiumLimits/plusPlaces``, each with its own name and radius.
    case extraPlaces

    /// The feed's history past ``PremiumLimits/freeHistory``, up to ``PremiumLimits/plusHistory``.
    case extendedHistory

    /// Filtering the feed by threat kind on top of "My places / All Ukraine".
    case feedFilters

    /// The morning report of the night around the user's places.
    case nightReport

    /// Voice rules: what to read, for which places, how fast.
    case voiceRules
}

/// The free and paid sizes of what is limited.
nonisolated enum PremiumLimits {

    /// How far back the free feed reaches.
    static let freeHistory: TimeInterval = 24 * 3_600

    /// How far back the feed is kept at all.
    static let plusHistory: TimeInterval = 90 * 24 * 3_600

    /// How many saved places the free plan watches: the home. The current location is always watched on top.
    static let freePlaces = 1

    /// How many saved places Plus watches, the home included.
    static let plusPlaces = 10
}
