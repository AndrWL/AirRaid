//
//  WidgetTime.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// How times read in the widgets: the same wording as the app's sheets (`DisplayTime`).
///
/// Only fixed moments, no running timers: between the app's updates a ticking timer looks live while the data behind
/// it is not, and a moment stays true however old the update is.
enum WidgetTime {

    /// «11:42».
    static let clockStyle = Date.FormatStyle(locale: Constants.locale).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)

    /// "Since" with the time today, with the day earlier.
    static func since(
        _ date: Date,
        now: Date
    ) -> String {
        if Calendar.current.isDate(date, inSameDayAs: now) {
            return "з \(date.formatted(clockStyle))"
        }
        return "з \(date.formatted(dayStyle))"
    }

    /// «≈ 10:42» — when the forecast puts the threat over the place; the «≈» marks it as an estimate, the way the app
    /// tags computed values as an estimate.
    static func arrival(_ date: Date) -> String {
        "≈ \(date.formatted(clockStyle))"
    }

    private static let dayStyle = Date.FormatStyle(locale: Constants.locale).day().month(.abbreviated)
}

// MARK: - Constants

private enum Constants {
    static let locale = Locale(identifier: "uk_UA")
}
