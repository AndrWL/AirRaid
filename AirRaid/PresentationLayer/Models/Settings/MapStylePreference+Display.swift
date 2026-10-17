//
//  MapStylePreference+Display.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 17.10.2026.
//

import Foundation

extension MapStylePreference {

    var title: String {
        switch self {
        case .system: "Як у системі"
        case .dark: "Темна"
        case .light: "Світла"
        case .detailed: "Детальна"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .dark: "moon"
        case .light: "sun.max"
        case .detailed: "tree"
        }
    }
}
