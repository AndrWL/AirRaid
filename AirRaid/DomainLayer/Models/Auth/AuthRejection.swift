//
//  AuthRejection.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Why the server refused credentials that the app still considered valid.
nonisolated enum AuthRejection: Equatable, Sendable {

    /// The token expired or was not accepted (`token_expired` / `token_invalid`, WebSocket close `4401`):
    /// get a new one.
    case tokenRejected

    /// The installation was revoked (`installation_revoked`, WebSocket close `4403`): a new token would be refused
    /// too, so the device must attest again.
    case installationRevoked
}
