//
//  RegionAlertExtent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// How much of a raion an alert covers, ordered from less to more.
nonisolated enum RegionAlertExtent: Int, Comparable, Sendable {

    /// Only a hromada inside the raion.
    case partial

    /// The whole raion.
    case whole

    static func < (lhs: RegionAlertExtent, rhs: RegionAlertExtent) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
