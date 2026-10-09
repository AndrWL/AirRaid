//
//  AuthServiceError.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Failures of ``AuthService`` itself, as opposed to the server's ``AuthAPIError``.
nonisolated enum AuthServiceError: Error, Equatable {

    /// Attestation is on hold: a recent attempt failed (until the date), or a key was already generated this launch.
    case attestationDeferred(until: Date?)

    /// The server rejected two fresh challenges in a row.
    case challengeRejected
}
