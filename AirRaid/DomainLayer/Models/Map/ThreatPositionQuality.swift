//
//  ThreatPositionQuality.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// What a threat's location is based on, from most to least precise.
nonisolated enum ThreatPositionQuality: Sendable {

    /// A settlement named in the reports.
    case confirmed

    /// An approximate place, e.g. "north of the city".
    case approximate

    /// Only the destination is known ("курсом на").
    case targetOnly

    /// Only the region is known.
    case area
}
