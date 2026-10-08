//
//  ThreatChangeDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// One entry of a `changes` message; ``type`` says which fields are present.
///
/// - `upsert`: a whole ``event``.
/// - `close`: its ``id`` and ``reason``; for `merged`, also ``mergedInto`` — the survivor's `upsert` comes in the same
///   message.
/// - `alert_on`: a whole ``alert``, replacing the one with the same `uid`.
/// - `alert_off`: the alert's ``uid`` and region ``code``.
nonisolated struct ThreatChangeDTO: Decodable, Sendable {

    let type: String
    let version: Int?
    let event: ThreatEventDTO?
    let id: String?
    /// `ended` (timed out or all-clear), `cancelled` (the channel deleted the report), or `merged` (a duplicate).
    let reason: String?
    let mergedInto: String?
    let alert: RegionAlertDTO?
    let uid: String?
    let code: String?

    enum CodingKeys: String, CodingKey {
        case type, version, event, id, reason, alert, uid, code
        case mergedInto = "merged_into"
    }
}
