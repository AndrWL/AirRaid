//
//  AuthAPIError.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// A non-2xx answer from the auth endpoints, with the backend's error code.
nonisolated struct AuthAPIError: Error, Equatable, Sendable {

    /// The backend's error codes the app acts on; others are only logged.
    enum Code {
        static let challengeInvalid = "challenge_invalid"
        static let attestationInvalid = "attestation_invalid"
        static let assertionInvalid = "assertion_invalid"
        static let installationUnknown = "installation_unknown"
        static let installationRevoked = "installation_revoked"
        static let keyAlreadyAttested = "key_already_attested"
        static let attestUnavailable = "attest_unavailable"
        static let upgradeRequired = "upgrade_required"
    }

    let statusCode: Int

    /// The `error` field, or `nil` when the body was not the backend's error JSON (e.g. a tunnel error page).
    let code: String?

    let message: String?

    /// `Retry-After` in seconds, sent with `429` and `503`.
    let retryAfter: TimeInterval?
}
