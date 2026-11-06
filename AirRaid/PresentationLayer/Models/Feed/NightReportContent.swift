//
//  NightReportContent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// The night around the user's places, from what the feed saw: how long the alerts lasted and what flew.
///
/// - Warning: Counts the tracks this device saw, not official figures: a night the app spent closed is incomplete.
struct NightReportContent: Hashable {

    /// One kind of threat and how many tracks of it.
    struct ThreatCount: Identifiable, Hashable {
        let id: String
        let title: String
        let iconName: String
        let count: Int
    }

    /// The night's title with its date.
    let title: String

    /// «20:00 – 08:00».
    let periodText: String

    /// The total time under an air raid alert in the user's oblasts, merged across places, in hours and minutes.
    let alertDurationText: String?

    /// The same, in seconds; `0` without an alert.
    let alertDuration: TimeInterval

    /// How many separate alerts were declared there.
    let alertCount: Int

    /// The tracks in the user's oblasts, by kind, most first.
    let nearbyThreats: [ThreatCount]

    /// Every track in the country.
    let countryThreatCount: Int

    /// Whether the user has a place at all; without one only the country counts mean anything.
    let hasPlaces: Bool

    var isQuiet: Bool {
        alertCount == 0 && nearbyThreats.isEmpty
    }
}

// MARK: - Factory

extension NightReportContent {

    /// The last night: 20:00 to 08:00, or to now if the morning has not come yet.
    static func make(
        items: [FeedItem],
        regionIDs: Set<String>,
        now: Date,
        calendar: Calendar = .current
    ) -> NightReportContent {
        let (start, end) = nightBounds(now: now, calendar: calendar)
        let inNight = items.filter { $0.createdAt < end && $0.updatedAt >= start }

        var alertIntervals: [(Date, Date)] = []
        var alertCount = 0
        var counts: [ThreatKind: Int] = [:]
        var countryThreatCount = 0
        for item in inNight {
            switch item.content {
            case .alert(let alert) where alert.kind == .airRaid && regionIDs.contains(alert.regionID):
                for place in alert.places where place.startedAt < end && (place.endedAt ?? now) > start {
                    alertCount += 1
                    alertIntervals.append((max(place.startedAt, start), min(place.endedAt ?? now, end)))
                }
            case .threat(let threat) where item.createdAt >= start:
                let count = max(threat.count ?? 1, 1)
                countryThreatCount += count
                if !item.regionIDs.isDisjoint(with: regionIDs) {
                    counts[threat.kind, default: 0] += count
                }
            default:
                continue
            }
        }

        let alertDuration = mergedDuration(alertIntervals)
        return NightReportContent(
            title: "Ніч на \(end.formatted(Constants.dayMonthStyle))",
            periodText: "\(start.formatted(DisplayTime.clockStyle)) – \(end.formatted(DisplayTime.clockStyle))",
            alertDurationText: alertDuration > 0 ? DisplayTime.duration(alertDuration) : nil,
            alertDuration: alertDuration,
            alertCount: alertCount,
            nearbyThreats: counts
                .sorted { $0.value > $1.value }
                .map { kind, count in
                    ThreatCount(id: "\(kind)", title: kind.displayName, iconName: ThreatIcon(kind).name, count: count)
                },
            countryThreatCount: countryThreatCount,
            hasPlaces: !regionIDs.isEmpty
        )
    }
}

// MARK: - Private methods

private extension NightReportContent {

    static func nightBounds(
        now: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        // Wall-clock hours, not hours after midnight: on the day the clocks change those are an hour off.
        let morning = calendar.date(bySettingHour: Constants.morningHour, minute: 0, second: 0, of: now) ?? now
        // Before the evening starts, "last night" is the one that ended this morning.
        let nightEnd = now < morning ? now : morning
        let eveningDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
        let start = calendar.date(bySettingHour: Constants.eveningHour, minute: 0, second: 0, of: eveningDay) ?? now
        return (start, nightEnd)
    }

    /// The time covered by any of the intervals, overlaps counted once.
    static func mergedDuration(_ intervals: [(Date, Date)]) -> TimeInterval {
        var total: TimeInterval = 0
        var current: (start: Date, end: Date)?
        for (start, end) in intervals.sorted(by: { $0.0 < $1.0 }) where end > start {
            if let open = current, start <= open.end {
                current = (open.start, max(open.end, end))
            } else {
                if let open = current {
                    total += open.end.timeIntervalSince(open.start)
                }
                current = (start, end)
            }
        }
        if let open = current {
            total += open.end.timeIntervalSince(open.start)
        }
        return total
    }
}

// MARK: - Constants

private enum Constants {
    static let eveningHour = 20
    static let morningHour = 8
    static let dayMonthStyle = Date.FormatStyle(locale: Locale(identifier: "uk_UA")).day().month(.wide)
}
