//
//  RegionAlertLevel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// The official danger level of an alert, ordered from lower to higher.
nonisolated enum RegionAlertLevel: Int, Comparable, Sendable {

    /// A lower threat, e.g. drones only.
    case yellow

    /// A higher threat, e.g. missiles; also an air raid published without a level.
    case red

    static func < (lhs: RegionAlertLevel, rhs: RegionAlertLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
