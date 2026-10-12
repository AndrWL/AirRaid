//
//  DisplayTime.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// How times and durations read across the map's sheets.
enum DisplayTime {

    /// «11:42».
    static let clockStyle = Date.FormatStyle(locale: Constants.locale).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)

    /// «1 год 52 хв», «20 хв», «2 д 5 год», «1651 д»; whole minutes, since seconds would only flicker, and whole days
    /// past a week — an alert in a frontline oblast can last for years.
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        guard minutes >= 60 else { return "\(minutes) хв" }
        let hours = minutes / 60
        let rest = minutes % 60
        let days = hours / 24
        guard days < 7 else { return "\(days) д" }
        guard days < 1 else { return "\(days) д \(hours % 24) год" }
        return rest > 0 ? "\(hours) год \(rest) хв" : "\(hours) год"
    }

    /// «з 10:28» today, «з 3 жовт., 22:10» earlier this year, «з 04.04.2022» before that.
    static func since(
        _ date: Date,
        now: Date
    ) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return "з \(date.formatted(clockStyle))"
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return "з \(date.formatted(dayStyle)), \(date.formatted(clockStyle))"
        }
        return "з \(date.formatted(dateStyle))"
    }

    private static let dayStyle = Date.FormatStyle(locale: Constants.locale).day().month(.abbreviated)

    private static let dateStyle = Date.FormatStyle(locale: Constants.locale)
        .day(.twoDigits)
        .month(.twoDigits)
        .year()
}

// MARK: - Constants

private enum Constants {
    static let locale = Locale(identifier: "uk_UA")
}
