//
//  ThreatLevel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// How much a threat report can be trusted, bucketed from ``Threat/confidence``.
///
/// Ordered from least to most trusted, so a "not below" filter is a plain comparison.
nonisolated enum ThreatLevel: Int, CaseIterable, Comparable, Sendable {

    /// Confidence below 0.6 — a single unconfirmed report.
    case low

    /// Confidence from 0.6 up to 0.9.
    case medium

    /// Confidence 0.9 and above.
    case high

    static func < (lhs: ThreatLevel, rhs: ThreatLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
