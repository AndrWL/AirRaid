//
//  FeedItemEntityMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Converts feed bubbles to and from their stored form.
nonisolated enum FeedItemEntityMapper {

    static func map(_ item: FeedItem) -> FeedItemEntity {
        var threat: FeedThreatEntity?
        var alert: FeedAlertEntity?
        switch item.content {
        case .threat(let value):
            threat = FeedThreatEntity(
                threatID: value.threatID,
                kind: name(value.kind),
                type: value.type.map(name),
                count: value.count,
                level: name(value.level),
                regionID: value.regionID,
                regionName: value.regionName,
                positionName: value.positionName,
                targetName: value.targetName,
                isCountryWide: value.isCountryWide
            )
        case .alert(let value):
            alert = FeedAlertEntity(
                kind: name(value.kind),
                level: value.level?.rawValue,
                regionID: value.regionID,
                places: value.places.map { place in
                    FeedAlertPlaceEntity(
                        alertID: place.alertID,
                        name: place.name,
                        scope: name(place.scope),
                        startedAt: place.startedAt,
                        endedAt: place.endedAt
                    )
                }
            )
        }
        return FeedItemEntity(
            id: item.id,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            isActive: item.isActive,
            priority: item.priority.rawValue,
            regionIDs: item.regionIDs.sorted(),
            lines: item.lines.map(map),
            droppedLineCount: item.droppedLineCount,
            threat: threat,
            alert: alert
        )
    }

    /// `nil` for a bubble whose content this build cannot read.
    static func map(_ entity: FeedItemEntity) -> FeedItem? {
        guard let content = content(of: entity) else { return nil }
        return FeedItem(
            id: entity.id,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            isActive: entity.isActive,
            priority: FeedPriority(rawValue: entity.priority) ?? .normal,
            regionIDs: Set(entity.regionIDs),
            lines: entity.lines.compactMap(map),
            droppedLineCount: entity.droppedLineCount,
            content: content
        )
    }
}

// MARK: - Content

nonisolated private extension FeedItemEntityMapper {

    static func content(of entity: FeedItemEntity) -> FeedContent? {
        if let threat = entity.threat,
           let kind: ThreatKind = value(named: threat.kind),
           let level: ThreatLevel = value(named: threat.level) {
            return .threat(FeedThreat(
                threatID: threat.threatID,
                kind: kind,
                type: threat.type.flatMap { value(named: $0) },
                count: threat.count,
                level: level,
                regionID: threat.regionID,
                regionName: threat.regionName,
                positionName: threat.positionName,
                targetName: threat.targetName,
                isCountryWide: threat.isCountryWide
            ))
        }
        if let alert = entity.alert, let kind: RegionAlertKind = value(named: alert.kind) {
            return .alert(FeedAlert(
                kind: kind,
                level: alert.level.flatMap(RegionAlertLevel.init(rawValue:)),
                regionID: alert.regionID,
                places: alert.places.map { place in
                    FeedAlertPlace(
                        alertID: place.alertID,
                        name: place.name,
                        scope: value(named: place.scope) ?? .unknown,
                        startedAt: place.startedAt,
                        endedAt: place.endedAt
                    )
                }
            ))
        }
        return nil
    }
}

// MARK: - Lines

nonisolated private extension FeedItemEntityMapper {

    // One case per event: an exhaustive switch keeps a new event from being saved without its fields.
    // swiftlint:disable:next cyclomatic_complexity
    static func map(_ line: FeedLine) -> FeedLineEntity {
        var entity = FeedLineEntity(date: line.date, event: LineEvent.name(of: line.event))
        switch line.event {
        case .threatAppeared(let regionName, let positionName, let targetName):
            entity.name = regionName
            entity.secondName = positionName
            entity.thirdName = targetName
        case .threatRefined(let kind, let type):
            entity.kind = name(kind)
            entity.type = type.map(name)
        case .threatCountChanged(let count):
            entity.number = count
        case .threatConfirmed(let level, let sourceCount):
            entity.level = name(level)
            entity.number = sourceCount
        case .threatCrossedRegion(let regionName):
            entity.name = regionName
        case .threatCourseChanged(let targetName):
            entity.name = targetName
        case .threatClosed(let reason):
            switch reason {
            case .ended: entity.reason = LineEvent.ended
            case .cancelled: entity.reason = LineEvent.cancelled
            case .merged(let survivorID):
                entity.reason = LineEvent.merged
                entity.survivorID = survivorID
            case .unknown: entity.reason = LineEvent.unknown
            }
        case .alertStarted(let placeName):
            entity.name = placeName
        case .alertLevelChanged(let level):
            entity.number = level.rawValue
        case .alertEnded(let placeName, let duration):
            entity.name = placeName
            entity.duration = duration
        }
        return entity
    }

    static func map(_ entity: FeedLineEntity) -> FeedLine? {
        event(of: entity).map { FeedLine(date: entity.date, event: $0) }
    }

    // swiftlint:disable:next cyclomatic_complexity
    static func event(of entity: FeedLineEntity) -> FeedLineEvent? {
        switch entity.event {
        case LineEvent.threatAppeared:
            return entity.name.map {
                .threatAppeared(regionName: $0, positionName: entity.secondName, targetName: entity.thirdName)
            }
        case LineEvent.threatRefined:
            guard let kind: ThreatKind = entity.kind.flatMap({ value(named: $0) }) else { return nil }
            return .threatRefined(kind: kind, type: entity.type.flatMap { value(named: $0) })
        case LineEvent.threatCountChanged:
            return entity.number.map { .threatCountChanged($0) }
        case LineEvent.threatConfirmed:
            guard let level: ThreatLevel = entity.level.flatMap({ value(named: $0) }) else { return nil }
            return .threatConfirmed(level: level, sourceCount: entity.number ?? 0)
        case LineEvent.threatCrossedRegion:
            return entity.name.map { .threatCrossedRegion(regionName: $0) }
        case LineEvent.threatCourseChanged:
            return entity.name.map { .threatCourseChanged(targetName: $0) }
        case LineEvent.threatClosed:
            return .threatClosed(closeReason(of: entity))
        case LineEvent.alertStarted:
            return entity.name.map { .alertStarted(placeName: $0) }
        case LineEvent.alertLevelChanged:
            return entity.number.flatMap(RegionAlertLevel.init(rawValue:)).map { .alertLevelChanged($0) }
        case LineEvent.alertEnded:
            return entity.name.map { .alertEnded(placeName: $0, duration: entity.duration ?? 0) }
        default:
            return nil
        }
    }

    static func closeReason(of entity: FeedLineEntity) -> ThreatCloseReason {
        switch entity.reason {
        case LineEvent.ended: .ended
        case LineEvent.cancelled: .cancelled
        case LineEvent.merged: .merged(survivorID: entity.survivorID)
        default: .unknown
        }
    }
}

// MARK: - Enum names

nonisolated private extension FeedItemEntityMapper {

    static func name<Value>(_ value: Value) -> String {
        String(describing: value)
    }

    static func value<Value: CaseIterable>(named name: String) -> Value? {
        Value.allCases.first { String(describing: $0) == name }
    }
}

// MARK: - Constants

nonisolated private enum LineEvent {
    static let threatAppeared = "threatAppeared"
    static let threatRefined = "threatRefined"
    static let threatCountChanged = "threatCountChanged"
    static let threatConfirmed = "threatConfirmed"
    static let threatCrossedRegion = "threatCrossedRegion"
    static let threatCourseChanged = "threatCourseChanged"
    static let threatClosed = "threatClosed"
    static let alertStarted = "alertStarted"
    static let alertLevelChanged = "alertLevelChanged"
    static let alertEnded = "alertEnded"

    static let ended = "ended"
    static let cancelled = "cancelled"
    static let merged = "merged"
    static let unknown = "unknown"

    static func name(of event: FeedLineEvent) -> String {
        switch event {
        case .threatAppeared: threatAppeared
        case .threatRefined: threatRefined
        case .threatCountChanged: threatCountChanged
        case .threatConfirmed: threatConfirmed
        case .threatCrossedRegion: threatCrossedRegion
        case .threatCourseChanged: threatCourseChanged
        case .threatClosed: threatClosed
        case .alertStarted: alertStarted
        case .alertLevelChanged: alertLevelChanged
        case .alertEnded: alertEnded
        }
    }
}
