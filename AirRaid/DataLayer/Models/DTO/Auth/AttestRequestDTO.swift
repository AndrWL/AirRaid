//
//  AttestRequestDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// `POST /v1/auth/attest` body. Binary fields are base64url.
nonisolated struct AttestRequestDTO: Encodable, Sendable {

    let keyId: String

    let attestation: String

    /// Base64url of the ``ClientDataDTO`` bytes whose SHA-256 went into the attestation.
    let clientData: String
}
