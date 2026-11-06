//
//  FeedRow.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// One bubble as the feed draws it.
struct FeedRow: Identifiable, Hashable {

    /// How the bubble is coloured.
    enum Tone: Hashable {
        /// Ended: muted.
        case quiet
        case normal
        /// Missiles, guided bombs, a red alert.
        case high
        /// Ballistics, country-wide, or inside the user's radius.
        case critical
        /// An all-clear.
        case allClear
    }

    /// A line of the bubble.
    struct Line: Identifiable, Hashable {
        let id: Int
        /// «02:44».
        let timeText: String
        let text: String
    }

    let id: String

    let title: String

    /// The current state, e.g. where the threat is and where it heads.
    let subtitle: String?

    /// An asset name for a threat, `nil` for an alert (``systemImage`` then).
    let iconName: String?

    let systemImage: String?

    let tone: Tone

    let isActive: Bool

    /// The time, with the day before today.
    let timeText: String

    /// The distance to the place and the estimated arrival — live, for an active threat with a known position.
    let proximityText: String?

    /// How many earlier lines were dropped.
    let droppedLinesText: String?

    let lines: [Line]

    /// Opens on the map: a threat still on it.
    let isOpenableOnMap: Bool
}

// MARK: - Factory

extension FeedRow {

    /// - Parameters:
    ///   - item: The bubble.
    ///   - threat: The live threat behind it, when still on the map.
    ///   - places: The watched places; the distance line names the nearest one.
    ///   - now: The moment for times and the forecast.
    init(
        item: FeedItem,
        threat: Threat?,
        places: [WatchedPlace],
        now: Date
    ) {
        let isNear = threat?.isNear(places) == true
        id = item.id
        title = FeedText.title(of: item)
        subtitle = FeedText.subtitle(of: item)
        isActive = item.isActive
        timeText = Self.timeText(item.createdAt, now: now)
        lines = item.lines.enumerated().map { index, line in
            Line(id: index, timeText: line.date.formatted(DisplayTime.clockStyle), text: FeedText.display(line))
        }
        droppedLinesText = item.droppedLineCount > 0
            ? "ще \(item.droppedLineCount) \(FeedText.plural(item.droppedLineCount, one: "рядок", few: "рядки", many: "рядків")) раніше"
            : nil
        isOpenableOnMap = threat != nil

        switch item.content {
        case .threat(let feedThreat):
            iconName = feedThreat.type.map { ThreatIcon($0).name } ?? ThreatIcon(feedThreat.kind).name
            systemImage = nil
        case .alert(let alert):
            iconName = nil
            systemImage = item.isActive ? alert.kind.systemImage : "checkmark.shield"
        }
        tone = Self.tone(of: item, isNear: isNear)
        proximityText = Self.proximityText(threat: threat, places: places, now: now)
    }
}

// MARK: - Private methods

private extension FeedRow {

    static func tone(
        of item: FeedItem,
        isNear: Bool
    ) -> Tone {
        if case .alert = item.content, !item.isActive {
            return .allClear
        }
        guard item.isActive else { return .quiet }
        if isNear {
            return .critical
        }
        switch item.priority {
        case .critical: return .critical
        case .high: return .high
        case .normal, .low: return .normal
        }
    }

    /// The distance from the nearest of the places, and whether the threat is inside its radius.
    static func proximityText(
        threat: Threat?,
        places: [WatchedPlace],
        now: Date
    ) -> String? {
        guard let threat else { return nil }
        // Without a position there is no distance; heading into a radius is still news.
        if let place = places.first(where: threat.isHeading(into:)) {
            return "ціль атаки \(place.nearText)"
        }
        let nearest = places
            .compactMap { place in threat.proximity(to: place.coordinate, at: now).map { (place, $0) } }
            .min { $0.1.distanceKm < $1.1.distanceKm }
        guard let (place, proximity) = nearest else { return nil }
        var parts = ["\(DisplayTime.distance(proximity)) \(place.fromText)"]
        if threat.isNear(place) {
            parts.append("у радіусі")
        } else if let time = proximity.timeToArrival {
            parts.append("\(place.arrivalLabel.lowercased()) \(DisplayTime.estimate(time))")
        }
        return parts.joined(separator: " · ")
    }

    static func timeText(
        _ date: Date,
        now: Date
    ) -> String {
        let time = date.formatted(DisplayTime.clockStyle)
        guard !Calendar.current.isDate(date, inSameDayAs: now) else { return time }
        return "\(date.formatted(Constants.dayStyle)), \(time)"
    }
}

// MARK: - RegionAlertKind

private extension RegionAlertKind {

    var systemImage: String {
        switch self {
        case .airRaid: "exclamationmark.triangle.fill"
        case .artilleryShelling: "burst.fill"
        case .urbanFights: "building.2.fill"
        case .chemical: "aqi.high"
        case .nuclear: "atom"
        case .unknown: "exclamationmark.triangle"
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let dayStyle = Date.FormatStyle(locale: Locale(identifier: "uk_UA")).day().month(.abbreviated)
}
