//
//  HomeAlertActivityState+Display.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The activity's three moods: an alert at the place, a threat in its radius with no alert there, and the all clear.
extension HomeAlertActivityState {

    /// An air raid alert, a threat nearby, or the all clear.
    var headline: String {
        if isAllClear {
            return "Відбій тривоги"
        }
        return alert == nil ? "Загроза поруч" : "Повітряна тривога"
    }

    /// One word each for alert, threat and all clear — for the Dynamic Island.
    var shortHeadline: String {
        if isAllClear {
            return "Відбій"
        }
        return alert == nil ? "Загроза" : "Тривога"
    }

    /// The alert's level, red for a threat with no alert, green for the all clear.
    var color: Color {
        if isAllClear {
            return .allClear
        }
        return alert?.level.color ?? .alertRed
    }

    var textColor: Color {
        if isAllClear {
            return .allClear
        }
        return alert?.level.textColor ?? .alertRed
    }

    var dotTone: StatusDot.Tone {
        if isAllClear {
            return .allClear
        }
        return alert?.level.dotTone ?? .alertRed
    }
}
