//
//  ThreatEventDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// One event (a threat's track) as the API sends it.
///
/// Fields added after the first API version are optional, so an older server does not break decoding.
/// Unknown fields are ignored.
nonisolated struct ThreatEventDTO: Decodable, Sendable {

    let id: String
    let kind: String
    let type: String?
    /// A refinement of `type` that older apps do not know; `type` then holds the closest known one
    /// (`molniya` comes as `type: "uav"`).
    let subtype: String?
    let count: Int?
    let level: String
    let confidence: Double
    let sources: Int
    let position: ThreatPlaceDTO?
    let target: ThreatPlaceDTO?
    /// `[[lat, lon, unix], …]`, oldest first.
    let trail: [[Double]]?
    let area: ThreatAreaDTO
    let positionQuality: String?
    let accuracyKm: Double?
    let headingDeg: Double?
    let fromDeg: Double?
    let speedKmh: Double?
    let speedSource: String?
    let movedAt: Int?
    let firstSeen: Int
    let updated: Int
    let expires: Int
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, type, subtype, count, level, confidence, sources, position, target, trail, area, summary, updated, expires
        case positionQuality = "position_quality"
        case accuracyKm = "accuracy_km"
        case headingDeg = "heading_deg"
        case fromDeg = "from_deg"
        case speedKmh = "speed_kmh"
        case speedSource = "speed_source"
        case movedAt = "moved_at"
        case firstSeen = "first_seen"
    }
}
