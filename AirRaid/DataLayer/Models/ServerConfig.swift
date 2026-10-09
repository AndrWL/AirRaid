//
//  ServerConfig.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// A server address that passed the signature and allow-list checks.
nonisolated struct ServerConfig: Equatable, Sendable {

    let apiServerURL: URL

    /// Unix seconds; an older config than the one already applied is a replay and is ignored.
    let issuedAt: Int64
}
