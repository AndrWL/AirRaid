//
//  ThreatTrackPoint.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// One earlier location of a threat on its ``Threat/trail``.
nonisolated struct ThreatTrackPoint: Hashable, Sendable {

    let coordinate: GeoCoordinate

    /// When the threat was reported at this location.
    let time: Date
}
