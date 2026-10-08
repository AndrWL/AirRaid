//
//  RegionAlertScope.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// The kind of place an alert is declared for.
nonisolated enum RegionAlertScope: Sendable {

    /// The whole oblast.
    case oblast

    case raion

    case hromada

    /// A city; for Kyiv and Sevastopol that is the whole region.
    case city

    /// A place type added to the source after this app was built.
    case unknown
}
