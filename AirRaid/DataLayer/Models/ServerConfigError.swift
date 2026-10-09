//
//  ServerConfigError.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Why no server address is available.
///
/// Retryable on purpose: the next connection attempt fetches the config again, and a fresh install without
/// a cached address has no other way to find the server.
nonisolated enum ServerConfigError: Error, Equatable {

    /// The signature does not match the backend's key.
    case invalidSignature

    /// The address is not `https` on an allowed host.
    case disallowedURL(String)

    /// No valid config was ever received and nothing is cached.
    case unavailable
}
