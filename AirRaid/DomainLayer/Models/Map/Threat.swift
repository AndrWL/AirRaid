//
//  Threat.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// The track of one threat, as monitoring channels report it.
///
/// Every new report about the same target replaces the whole value under the same ``id``: a newer
/// ``position``, a longer ``trail``, a higher ``confidence``.
nonisolated struct Threat: Identifiable, Hashable, Sendable {

    /// A stable identifier, so the same threat keeps its pin across updates.
    let id: String

    /// The broad category, always known.
    let kind: ThreatKind

    /// The specific type, or `nil` when the source does not name it — show ``kind`` then.
    let type: ThreatType?

    /// How many targets, when the channels name a number.
    let count: Int?

    /// How much the report can be trusted.
    let level: ThreatLevel

    /// Trust in `0...1`; grows with every independent confirmation.
    let confidence: Double

    /// How many independent channels confirmed the report.
    let sourceCount: Int

    /// The last confirmed location, or `nil` when only the ``target`` or the ``area`` is known.
    let position: ThreatPlace?

    /// Where the threat is heading ("курсом на"); may come together with ``position``.
    let target: ThreatPlace?

    /// Earlier locations, oldest first, up to 20 points.
    let trail: [ThreatTrackPoint]

    /// The region the threat is in.
    let area: ThreatArea

    /// What the location is based on.
    let positionQuality: ThreatPositionQuality

    /// The uncertainty radius around the shown location, in kilometres; `0` for a country-wide report.
    let accuracyKm: Double

    /// The direction of travel in degrees clockwise from north, or `nil` when unknown.
    let heading: Double?

    /// The direction the threat comes from, in degrees clockwise from north, or `nil` when unknown.
    let approachBearing: Double?

    /// Speed used to forecast movement between reports; `0` means "do not move".
    let speedKmh: Double

    /// Whether ``speedKmh`` was measured along the track or is typical for the type.
    let speedSource: ThreatSpeedSource

    /// When the threat reached its current ``position``; the start of the movement forecast.
    let movedAt: Date

    /// The first report about the threat.
    let firstSeenAt: Date

    /// The latest report about the threat.
    let updatedAt: Date

    /// When the threat closes unless a new report arrives.
    let expiresAt: Date

    /// A ready-made caption for lists and notifications, or `nil` from a server that does not send it.
    let summary: String?
}

// MARK: - Computed properties

nonisolated extension Threat {

    /// The report covers the whole country rather than a place — show a banner, not a pin.
    var isCountryWide: Bool {
        area.isCountryWide
    }

    /// Where to put the threat's pin: its position, else its target, else its region's center.
    ///
    /// `nil` for a country-wide report, which has no meaningful place on the map.
    var markerCoordinate: GeoCoordinate? {
        if let position {
            return position.coordinate
        }
        if let target {
            return target.coordinate
        }
        return isCountryWide ? nil : area.center
    }
}
