//
//  Threat.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// A threat spotted at a location, shown as a pin on the map.
nonisolated struct Threat: Identifiable, Hashable, Sendable {

    /// A stable identifier, so the same threat keeps its pin across updates.
    let id: String

    /// The broad category, always known.
    let kind: ThreatKind

    /// The specific type, or `nil` when the source does not name it — show ``kind`` then.
    let type: ThreatType?

    /// Where the threat was spotted.
    ///
    /// - Note: Public alert APIs only report the region, not a position. In that case the backend
    ///   sends the region's center.
    let coordinate: GeoCoordinate

    /// The direction of travel in degrees clockwise from north, or `nil` when unknown.
    let heading: Double?

    /// Speed in km/h used to forecast movement, or `nil` when there is no forecast.
    ///
    /// A typical speed for the type until the backend measures the real one from the track.
    let speedKmh: Double?

    /// When the threat was spotted.
    let detectedAt: Date
}
