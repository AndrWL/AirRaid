//
//  RegionAlert.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// An active air raid alert in one region.
nonisolated struct RegionAlert: Hashable, Sendable {

    /// The ISO 3166-2 code of the region, matching ``RegionBoundary/id``.
    let regionID: String

    /// When the alert was declared.
    let startedAt: Date
}
