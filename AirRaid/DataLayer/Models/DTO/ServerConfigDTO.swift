//
//  ServerConfigDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// The signed server address published by the config Worker: `GET /config.json`.
nonisolated struct ServerConfigDTO: Decodable, Sendable {

    /// The current API server, `https://<name>.trycloudflare.com` while the backend runs behind a quick tunnel.
    let apiServerURL: String

    /// Unix seconds when the address was published; never goes back for a genuine config.
    let issuedAt: Int64

    /// Base64url Ed25519 signature over the UTF-8 string `apiServerURL + "\n" + issuedAt`.
    let sig: String
}
