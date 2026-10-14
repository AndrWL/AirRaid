//
//  FeedFixtures.swift
//  AirRaidTests
//

import Foundation
@testable import AirRaid

/// Shared moments for the feed tests: a fixed origin, so every date is an offset from it.
enum FeedFixtures {

    /// 2026-10-14 00:00:00 UTC.
    static let origin = Date(timeIntervalSince1970: 1_791_936_000)

    static func date(_ offset: TimeInterval) -> Date {
        origin.addingTimeInterval(offset)
    }
}

// MARK: - Threat

extension Threat {

    static func stub(
        id: String = "t1",
        kind: ThreatKind = .drone,
        type: ThreatType? = .shahed,
        count: Int? = nil,
        level: ThreatLevel = .medium,
        sourceCount: Int = 2,
        regionID: String = "UA-32",
        regionName: String = "Київська область",
        positionName: String? = "Біла Церква",
        targetName: String? = nil,
        firstSeenAt: Date = FeedFixtures.origin,
        updatedAt: Date? = nil
    ) -> Threat {
        let updatedAt = updatedAt ?? firstSeenAt
        let coordinate = GeoCoordinate(latitude: 49.8, longitude: 30.1)
        return Threat(
            id: id,
            kind: kind,
            type: type,
            count: count,
            level: level,
            confidence: 0.7,
            sourceCount: sourceCount,
            position: positionName.map { ThreatPlace(name: $0, coordinate: coordinate) },
            target: targetName.map { ThreatPlace(name: $0, coordinate: coordinate) },
            trail: [],
            area: ThreatArea(name: regionName, regionID: regionID, center: coordinate),
            positionQuality: .confirmed,
            accuracyKm: 5,
            heading: nil,
            approachBearing: nil,
            speedKmh: 150,
            speedSource: .typical,
            movedAt: updatedAt,
            firstSeenAt: firstSeenAt,
            updatedAt: updatedAt,
            expiresAt: updatedAt.addingTimeInterval(1_800),
            summary: nil
        )
    }
}

// MARK: - RegionAlert

extension RegionAlert {

    static func stub(
        id: String = "a1",
        kind: RegionAlertKind = .airRaid,
        level: RegionAlertLevel? = nil,
        scope: RegionAlertScope = .raion,
        name: String = "Бучанський район",
        regionID: String = "UA-32",
        startedAt: Date = FeedFixtures.origin
    ) -> RegionAlert {
        RegionAlert(
            id: id,
            kind: kind,
            level: level,
            scope: scope,
            name: name,
            regionID: regionID,
            district: nil,
            startedAt: startedAt
        )
    }
}

// MARK: - FeedItem

extension FeedItem {

    static func stub(
        id: String = "threat:t1",
        createdAt: Date = FeedFixtures.origin,
        updatedAt: Date? = nil,
        isActive: Bool = true,
        priority: FeedPriority = .normal,
        regionIDs: Set<String> = ["UA-32"],
        lines: [FeedLine] = [],
        droppedLineCount: Int = 0,
        content: FeedContent = .threat(.stub())
    ) -> FeedItem {
        FeedItem(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt ?? createdAt,
            isActive: isActive,
            priority: priority,
            regionIDs: regionIDs,
            lines: lines,
            droppedLineCount: droppedLineCount,
            content: content
        )
    }
}

extension FeedThreat {

    static func stub(
        threatID: String = "t1",
        kind: ThreatKind = .drone,
        type: ThreatType? = .shahed,
        count: Int? = nil,
        regionID: String = "UA-32"
    ) -> FeedThreat {
        FeedThreat(
            threatID: threatID,
            kind: kind,
            type: type,
            count: count,
            level: .medium,
            regionID: regionID,
            regionName: "Київська область",
            positionName: "Біла Церква",
            targetName: nil,
            isCountryWide: false
        )
    }
}

extension FeedAlert {

    static func stub(
        kind: RegionAlertKind = .airRaid,
        level: RegionAlertLevel? = nil,
        regionID: String = "UA-32",
        places: [FeedAlertPlace] = [.stub()]
    ) -> FeedAlert {
        FeedAlert(kind: kind, level: level, regionID: regionID, places: places)
    }
}

extension FeedAlertPlace {

    static func stub(
        alertID: String = "a1",
        name: String = "Бучанський район",
        scope: RegionAlertScope = .raion,
        startedAt: Date = FeedFixtures.origin,
        endedAt: Date? = nil
    ) -> FeedAlertPlace {
        FeedAlertPlace(alertID: alertID, name: name, scope: scope, startedAt: startedAt, endedAt: endedAt)
    }
}
