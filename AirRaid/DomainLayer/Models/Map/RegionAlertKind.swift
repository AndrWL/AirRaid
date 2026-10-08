//
//  RegionAlertKind.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// What an official alert is about.
nonisolated enum RegionAlertKind: Sendable {

    /// Air raid — the alert the map fills regions for.
    case airRaid

    case artilleryShelling

    case urbanFights

    case chemical

    case nuclear

    /// A kind added to the source after this app was built.
    case unknown
}
