//
//  MapStylePreference.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 17.10.2026.
//

import Foundation

/// How the user wants the base map to look.
nonisolated enum MapStylePreference: String, CaseIterable, Sendable {

    /// Dark with the system's dark appearance, light otherwise.
    case system

    /// A dark, quiet map: the alert fills stand out the most.
    case dark

    /// A light, quiet map.
    case light

    /// A light map with forests, water and buildings: more to orient by, at the cost of the fills' contrast.
    case detailed
}
