//
//  FeedBuilder.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Turns changes of the air situation into feed bubbles, keeping only what matters to a person.
///
/// The rules:
/// - one threat is one bubble; a new report adds a line only when something significant changed: the type, the count,
///   the confidence went up, it crossed into another oblast, it flies somewhere else, it closed. A plain move updates
///   the bubble's header and adds nothing;
/// - lines of the same kind come at most once per ``Constants/throttleInterval`` per bubble;
/// - official alerts of one kind in one oblast declared within ``Constants/alertGroupWindow`` of each other share a
///   bubble, which ends when all of them have;
/// - a duplicate closed as `merged` disappears: for a person it was always one target;
/// - alerts that started more than ``Constants/staleAlertAge`` ago are a background state (frontline oblasts have had
///   one for years) and get no bubble.
nonisolated struct FeedBuilder: Sendable {

    // MARK: - Variables

    /// The bubbles by id.
    private(set) var items: [String: FeedItem]

    init(items: [FeedItem] = []) {
        self.items = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
    }

    // MARK: - Methods

    /// Applies the changes in order.
    ///
    /// - Returns: The lines added, in order, each with its bubble as it is after the whole batch.
    mutating func apply(
        _ events: [AirSituationEvent],
        now: Date
    ) -> [FeedEntry] {
        var added: [(itemID: String, line: FeedLine)] = []
        for event in events {
            switch event {
            case .threatUpdated(let threat, _):
                added += updateThreat(threat).map { (Self.threatItemID(threat.id), $0) }
            case .threatClosed(let threat, let reason, let date):
                added += closeThreat(threat, reason: reason, at: date).map { (Self.threatItemID(threat.id), $0) }
            case .alertStarted(let alert, let previous):
                added += startAlert(alert, previous: previous, now: now)
            case .alertEnded(let alert, let date):
                added += endAlert(alert, at: date)
            }
        }
        return added.compactMap { itemID, line in
            items[itemID].map { FeedEntry(item: $0, line: line) }
        }
    }

    /// Closes the bubbles whose threat or alert is no longer in the situation — they ended while nobody was listening,
    /// for example while the app was closed. Adds no lines worth reading aloud, so returns nothing.
    mutating func reconcile(
        with situation: AirSituation,
        now: Date
    ) {
        let threatIDs = Set(situation.threats.map(\.id))
        let alertIDs = Set(situation.alerts.map(\.id))
        for (id, item) in items where item.isActive {
            var item = item
            switch item.content {
            case .threat(let threat) where !threatIDs.contains(threat.threatID):
                item.isActive = false
                item.append(FeedLine(date: now, event: .threatClosed(.unknown)))
            case .alert(var alert):
                var changed = false
                for index in alert.places.indices where alert.places[index].endedAt == nil
                    && !alertIDs.contains(alert.places[index].alertID) {
                    alert.places[index].endedAt = now
                    changed = true
                }
                guard changed else { continue }
                item.content = .alert(alert)
                item.isActive = alert.places.contains { $0.endedAt == nil }
                item.updatedAt = now
            case .threat:
                continue
            }
            items[id] = item
        }
    }

    /// Forgets bubbles that ended before the date: the history kept is limited.
    mutating func prune(endedBefore date: Date) {
        items = items.filter { $0.value.isActive || $0.value.updatedAt >= date }
    }
}

// MARK: - Threats

nonisolated private extension FeedBuilder {

    static func threatItemID(_ threatID: String) -> String {
        "threat:\(threatID)"
    }

    mutating func updateThreat(_ threat: Threat) -> [FeedLine] {
        let id = Self.threatItemID(threat.id)
        let current = FeedThreat(threat)
        guard var item = items[id] else {
            let line = FeedLine(
                date: threat.firstSeenAt,
                event: .threatAppeared(
                    regionName: current.regionName,
                    positionName: current.positionName,
                    targetName: current.targetName
                )
            )
            items[id] = FeedItem(
                id: id,
                createdAt: threat.firstSeenAt,
                updatedAt: max(threat.firstSeenAt, threat.updatedAt),
                isActive: true,
                priority: current.priority,
                regionIDs: current.isCountryWide ? [] : [current.regionID],
                lines: [line],
                droppedLineCount: 0,
                content: .threat(current)
            )
            return [line]
        }
        guard case .threat(let previous) = item.content else { return [] }

        let date = threat.updatedAt
        var lines: [FeedLine] = []
        for event in Self.significantChanges(from: previous, to: current, sourceCount: threat.sourceCount) {
            let line = FeedLine(date: date, event: event)
            guard !item.isThrottled(line) else { continue }
            item.append(line)
            lines.append(line)
        }
        if !current.isCountryWide {
            item.regionIDs.insert(current.regionID)
        }
        // A closed track that a new report brings back carries on in the same bubble.
        item.isActive = true
        item.priority = current.priority
        item.content = .threat(current)
        item.updatedAt = max(item.updatedAt, date)
        items[id] = item
        return lines
    }

    /// What changed in a way a person cares about; a plain move is not in the list.
    static func significantChanges(
        from previous: FeedThreat,
        to current: FeedThreat,
        sourceCount: Int
    ) -> [FeedLineEvent] {
        var events: [FeedLineEvent] = []
        if previous.kind != current.kind || previous.type != current.type {
            events.append(.threatRefined(kind: current.kind, type: current.type))
        }
        if let count = current.count, count != previous.count {
            events.append(.threatCountChanged(count))
        }
        if current.level > previous.level {
            events.append(.threatConfirmed(level: current.level, sourceCount: sourceCount))
        }
        if current.regionID != previous.regionID, !current.isCountryWide {
            events.append(.threatCrossedRegion(regionName: current.regionName))
        }
        if let target = current.targetName, target != previous.targetName {
            events.append(.threatCourseChanged(targetName: target))
        }
        return events
    }

    mutating func closeThreat(
        _ threat: Threat,
        reason: ThreatCloseReason,
        at date: Date
    ) -> [FeedLine] {
        let id = Self.threatItemID(threat.id)
        if case .merged = reason {
            items[id] = nil
            return []
        }
        guard var item = items[id], item.isActive else { return [] }
        let line = FeedLine(date: date, event: .threatClosed(reason))
        item.isActive = false
        item.append(line)
        items[id] = item
        return [line]
    }
}

// MARK: - Alerts

nonisolated private extension FeedBuilder {

    mutating func startAlert(
        _ alert: RegionAlert,
        previous: RegionAlert?,
        now: Date
    ) -> [(itemID: String, line: FeedLine)] {
        // Already in a bubble: a replacement (a new level) or the same alert again after a reconnect.
        if var item = activeItem(containing: alert.id), case .alert(var group) = item.content {
            guard let previous, previous.level != alert.level, let level = alert.level else { return [] }
            let line = FeedLine(date: now, event: .alertLevelChanged(level))
            // Places keep no level of their own, so a group can only go up; a single place follows its alert.
            group.level = group.places.count == 1 ? level : max(group.level ?? level, level)
            item.content = .alert(group)
            item.append(line)
            items[item.id] = item
            return [(item.id, line)]
        }
        guard now.timeIntervalSince(alert.startedAt) < Constants.staleAlertAge else { return [] }

        let place = FeedAlertPlace(alertID: alert.id, name: alert.name, scope: alert.scope, startedAt: alert.startedAt)
        let line = FeedLine(date: alert.startedAt, event: .alertStarted(placeName: alert.name))
        if var item = groupItem(for: alert), case .alert(var group) = item.content {
            group.places.append(place)
            group.level = [group.level, alert.level].compactMap { $0 }.max()
            item.content = .alert(group)
            item.priority = max(item.priority, FeedPriority.of(alert))
            item.append(line)
            items[item.id] = item
            return [(item.id, line)]
        }
        let id = "alert:\(alert.regionID):\(alert.kind):\(Int(alert.startedAt.timeIntervalSince1970))"
        items[id] = FeedItem(
            id: id,
            createdAt: alert.startedAt,
            updatedAt: alert.startedAt,
            isActive: true,
            priority: FeedPriority.of(alert),
            regionIDs: [alert.regionID],
            lines: [line],
            droppedLineCount: 0,
            content: .alert(FeedAlert(kind: alert.kind, level: alert.level, regionID: alert.regionID, places: [place]))
        )
        return [(id, line)]
    }

    mutating func endAlert(
        _ alert: RegionAlert,
        at date: Date
    ) -> [(itemID: String, line: FeedLine)] {
        guard var item = activeItem(containing: alert.id),
              case .alert(var group) = item.content,
              let index = group.places.firstIndex(where: { $0.alertID == alert.id && $0.endedAt == nil }) else {
            return []
        }
        group.places[index].endedAt = date
        let line = FeedLine(
            date: date,
            event: .alertEnded(placeName: alert.name, duration: date.timeIntervalSince(group.places[index].startedAt))
        )
        item.content = .alert(group)
        item.isActive = group.places.contains { $0.endedAt == nil }
        item.append(line)
        items[item.id] = item
        return [(item.id, line)]
    }

    /// The active bubble that lists the alert as still going.
    func activeItem(containing alertID: String) -> FeedItem? {
        items.values.first { item in
            guard item.isActive, case .alert(let group) = item.content else { return false }
            return group.places.contains { $0.alertID == alertID && $0.endedAt == nil }
        }
    }

    /// The active bubble a new alert joins: same oblast, same kind, its latest alert declared just before.
    func groupItem(for alert: RegionAlert) -> FeedItem? {
        items.values.first { item in
            guard item.isActive,
                  case .alert(let group) = item.content,
                  group.regionID == alert.regionID,
                  group.kind == alert.kind,
                  let latest = group.places.map(\.startedAt).max() else { return false }
            return abs(alert.startedAt.timeIntervalSince(latest)) <= Constants.alertGroupWindow
        }
    }
}

// MARK: - FeedItem

nonisolated private extension FeedItem {

    /// A line of the same kind was added too recently; the first and the last line of a track always go through.
    func isThrottled(_ line: FeedLine) -> Bool {
        switch line.event {
        case .threatAppeared, .threatClosed, .alertStarted, .alertEnded:
            return false
        default:
            guard let last = lines.last(where: { $0.event.family == line.event.family }) else { return false }
            return line.date.timeIntervalSince(last.date) < Constants.throttleInterval
        }
    }
}

// MARK: - FeedThreat

nonisolated extension FeedThreat {

    init(_ threat: Threat) {
        self.init(
            threatID: threat.id,
            kind: threat.kind,
            type: threat.type,
            count: threat.count,
            level: threat.level,
            regionID: threat.area.regionID,
            regionName: threat.area.name,
            positionName: threat.position?.name,
            targetName: threat.target?.name,
            isCountryWide: threat.isCountryWide
        )
    }

    /// Ballistics and country-wide reports first, unconfirmed reports and reconnaissance last.
    var priority: FeedPriority {
        if isCountryWide || kind == .ballisticMissile {
            return .critical
        }
        if level == .low || type == .reconDrone {
            return .low
        }
        switch kind {
        case .missile, .guidedAerialBomb, .aviation:
            return .high
        case .drone, .fpv, .unknown, .ballisticMissile:
            return .normal
        }
    }
}

// MARK: - FeedPriority

nonisolated extension FeedPriority {

    static func of(_ alert: RegionAlert) -> FeedPriority {
        switch alert.kind {
        case .chemical, .nuclear: .critical
        case .artilleryShelling, .urbanFights: .high
        case .airRaid, .unknown: .normal
        }
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let throttleInterval: TimeInterval = 180
    static let alertGroupWindow: TimeInterval = 120
    static let staleAlertAge: TimeInterval = 24 * 3_600
}
