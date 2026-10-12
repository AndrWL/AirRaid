//
//  MapSelection.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// What the user picked on the map: a threat pin or, when the tap hit no pin, the region under it.
enum MapSelection: Hashable {

    /// The threat with this id.
    case threat(id: String)

    /// The region with this ISO 3166-2 code.
    case region(id: String)
}
