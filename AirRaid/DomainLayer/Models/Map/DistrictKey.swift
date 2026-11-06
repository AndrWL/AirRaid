//
//  DistrictKey.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// Identifies a raion the way alerts name it: its oblast plus its short Ukrainian name.
///
/// Alerts carry no raion code, only a name such as Haisyn Raion; names repeat across oblasts,
/// so the oblast is part of the key.
nonisolated struct DistrictKey: Hashable, Sendable {

    /// The ISO 3166-2 code of the oblast, matching ``RegionBoundary/id``.
    let regionID: String

    /// The raion name without the word for "raion", e.g. `Haisynskyi`.
    let name: String
}
