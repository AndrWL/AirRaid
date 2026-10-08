//
//  RealtimeMessageDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Any server → client WebSocket message; ``type`` says which fields are present.
///
/// - `snapshot`: ``version``, ``serverTime``, ``events``, ``alerts`` — the full state.
/// - `changes`: ``version``, ``changes`` — apply in order.
/// - `pong`: ``version``.
///
/// One malformed event, alert, or change is dropped instead of failing the whole message. ``alerts`` is `nil` from a
/// server without alert support.
nonisolated struct RealtimeMessageDTO: Decodable, Sendable {

    let type: String
    let version: Int?
    let serverTime: Int?
    let events: [ThreatEventDTO]?
    let changes: [ThreatChangeDTO]?
    let alerts: [RegionAlertDTO]?

    enum CodingKeys: String, CodingKey {
        case type, version, events, changes, alerts
        case serverTime = "server_time"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        version = try container.decodeIfPresent(Int.self, forKey: .version)
        serverTime = try container.decodeIfPresent(Int.self, forKey: .serverTime)
        events = try container.decodeIfPresent([FailableDTO<ThreatEventDTO>].self, forKey: .events)?
            .compactMap(\.value)
        changes = try container.decodeIfPresent([FailableDTO<ThreatChangeDTO>].self, forKey: .changes)?
            .compactMap(\.value)
        alerts = try container.decodeIfPresent([FailableDTO<RegionAlertDTO>].self, forKey: .alerts)?
            .compactMap(\.value)
    }
}
