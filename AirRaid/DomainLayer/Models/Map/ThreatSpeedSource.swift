//
//  ThreatSpeedSource.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Where ``Threat/speedKmh`` comes from.
nonisolated enum ThreatSpeedSource: Sendable {

    /// Measured from the time between points on the track.
    case measured

    /// A typical speed for the threat type; the track is too short to measure.
    case typical
}
