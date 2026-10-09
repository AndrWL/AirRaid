//
//  ClientDataDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// The JSON whose exact bytes App Attest signs: `{"challenge":"…"}`.
///
/// The server hashes the bytes it receives as is, so the encoding only has to be deterministic, not canonical.
nonisolated struct ClientDataDTO: Encodable, Sendable {

    /// The challenge string exactly as `/v1/auth/challenge` returned it.
    let challenge: String
}
