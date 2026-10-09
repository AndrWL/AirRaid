//
//  AccessTokenDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// The token response shared by `/attest`, `/token`, `/dev/token` and `/token/unattested`.
nonisolated struct AccessTokenDTO: Decodable, Sendable {

    let accessToken: String

    /// Seconds the token lives; preferred over `expiresAt` because the device clock may be off.
    let expiresIn: Int

    /// `attested`, `dev` or `unattested`; absent or unknown values count as attested.
    let kind: String?
}
