//
//  TokenRequestDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// `POST /v1/auth/token` body. Binary fields are base64url.
nonisolated struct TokenRequestDTO: Encodable, Sendable {

    let keyId: String

    /// Base64url of the ``ClientDataDTO`` bytes whose SHA-256 went into the assertion.
    let clientData: String

    let assertion: String
}
