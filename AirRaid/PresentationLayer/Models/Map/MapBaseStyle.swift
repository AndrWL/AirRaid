//
//  MapBaseStyle.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 17.10.2026.
//

import SwiftUI

/// The base map actually drawn: the user's ``MapStylePreference`` with «Як у системі» resolved by the appearance.
enum MapBaseStyle: Hashable {
    case dark
    case light
    case detailed

    /// The detailed map in dark colours, for the system's dark appearance.
    case detailedDark

    init(
        _ preference: MapStylePreference,
        colorScheme: ColorScheme
    ) {
        switch preference {
        case .system: self = colorScheme == .dark ? .dark : .light
        case .dark: self = .dark
        case .light: self = .light
        case .detailed: self = colorScheme == .dark ? .detailedDark : .detailed
        }
    }

    /// The OpenFreeMap style.
    var styleURL: URL {
        let string = switch self {
        case .dark: AppEnvironment.mapStyleURLString
        case .light: AppEnvironment.lightMapStyleURLString
        case .detailed, .detailedDark: AppEnvironment.detailedMapStyleURLString
        }
        guard let url = URL(string: string) else {
            fatalError("[MapBaseStyle] Invalid map style URL: \(string)")
        }
        return url
    }

    /// Whether the map is dark, so the map's own labels, outlines and tracks are light, or the other way round.
    var isDark: Bool {
        self == .dark || self == .detailedDark
    }

    /// Whether the downloaded style is light and has to be recoloured dark on the device: OpenFreeMap has no dark
    /// detailed style.
    var darkensBasemap: Bool {
        self == .detailedDark
    }
}
