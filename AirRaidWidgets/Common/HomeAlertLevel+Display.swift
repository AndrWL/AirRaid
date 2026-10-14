//
//  HomeAlertLevel+Display.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

extension HomeAlertLevel {

    /// The alert's colour, the same as the map's fill: dots and the Dynamic Island's keyline.
    var color: Color {
        switch self {
        case .red: return .alertRed
        case .yellow: return .alertYellow
        }
    }

    /// For text: the yellow is 2:1 on a light surface, so text takes its dark ink there.
    var textColor: Color {
        switch self {
        case .red: return .alertRed
        case .yellow: return .alertYellowInk
        }
    }

    var dotTone: StatusDot.Tone {
        switch self {
        case .red: return .alertRed
        case .yellow: return .alertYellow
        }
    }
}

// MARK: - HomeAlert

extension Optional where Wrapped == HomeAlert {

    /// «Повітряна тривога» or «Тривоги немає», as the app's home sheet reads.
    var title: String {
        self == nil ? "Тривоги немає" : "Повітряна тривога"
    }

    /// One word for the tightest spots: «Тривога», «Тихо».
    var shortTitle: String {
        self == nil ? "Тихо" : "Тривога"
    }

    var dotTone: StatusDot.Tone {
        self?.level.dotTone ?? .allClear
    }

    var systemImage: String {
        self == nil ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
    }
}
