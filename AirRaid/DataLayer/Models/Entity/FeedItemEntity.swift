//
//  FeedItemEntity.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// A ``FeedItem`` as it is kept on disk. Enums are stored by case name, so reordering cases breaks nothing;
/// a name this build does not know drops the line or the bubble rather than the whole history.
nonisolated struct FeedItemEntity: Codable, Sendable {

    let id: String
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    let priority: Int
    let regionIDs: [String]
    let lines: [FeedLineEntity]
    let droppedLineCount: Int
    let threat: FeedThreatEntity?
    let alert: FeedAlertEntity?
}

/// A ``FeedThreat`` on disk.
nonisolated struct FeedThreatEntity: Codable, Sendable {
    let threatID: String
    let kind: String
    let type: String?
    let count: Int?
    let level: String
    let regionID: String
    let regionName: String
    let positionName: String?
    let targetName: String?
    let isCountryWide: Bool
}

/// A ``FeedAlert`` on disk.
nonisolated struct FeedAlertEntity: Codable, Sendable {
    let kind: String
    let level: Int?
    let regionID: String
    let places: [FeedAlertPlaceEntity]
}

/// A ``FeedAlertPlace`` on disk.
nonisolated struct FeedAlertPlaceEntity: Codable, Sendable {
    let alertID: String
    let name: String
    let scope: String
    let startedAt: Date
    let endedAt: Date?
}

/// A ``FeedLine`` on disk: the event's case name plus whichever fields it carries.
nonisolated struct FeedLineEntity: Codable, Sendable {
    let date: Date
    let event: String
    var name: String?
    var secondName: String?
    var thirdName: String?
    var kind: String?
    var type: String?
    var number: Int?
    var level: String?
    var duration: TimeInterval?
    var reason: String?
    var survivorID: String?
}
