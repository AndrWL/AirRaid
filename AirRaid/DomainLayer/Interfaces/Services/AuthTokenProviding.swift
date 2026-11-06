//
//  AuthTokenProviding.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Supplies bearer tokens for the Nebo API and reacts when the server refuses one.
nonisolated protocol AuthTokenProviding: Sendable {

    /// A token valid for the next request or connection attempt.
    ///
    /// Returns the current token while it is fresh; otherwise gets a new one — App Attest on devices, the developer
    /// key on the simulator, a limited token where attestation is impossible. Concurrent callers share one request.
    ///
    /// - Throws: When no token can be obtained now; callers retry with their own backoff.
    func fetchAccessToken() async throws -> String

    /// Forgets credentials the server refused, so the next ``fetchAccessToken()`` gets new ones.
    func handleRejection(_ rejection: AuthRejection) async
}
