//
//  FeedFixtures.swift
//  AirRaidTests
//

import Foundation
@testable import AirRaid

/// Shared moments for the tests: a fixed origin, so every date is an offset from it.
enum FeedFixtures {

    /// 2026-10-14 00:00:00 UTC.
    static let origin = Date(timeIntervalSince1970: 1_791_936_000)

    static func date(_ offset: TimeInterval) -> Date {
        origin.addingTimeInterval(offset)
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
