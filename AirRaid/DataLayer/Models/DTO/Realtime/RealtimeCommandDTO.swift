//
//  RealtimeCommandDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A client → server WebSocket message.
nonisolated struct RealtimeCommandDTO: Encodable, Sendable {

    let type: String
    let since: Int?
    let regions: [String]?
    let minLevel: String?
    let kinds: [String]?

    enum CodingKeys: String, CodingKey {
        case type, since, regions, kinds
        case minLevel = "min_level"
    }

    /// Asks for a fresh `snapshot`. With no filters — every region, level, and kind.
    static func subscribe(
        regions: [String]? = nil,
        minLevel: String? = nil,
        kinds: [String]? = nil
    ) -> RealtimeCommandDTO {
        RealtimeCommandDTO(type: "subscribe", since: nil, regions: regions, minLevel: minLevel, kinds: kinds)
    }
}
