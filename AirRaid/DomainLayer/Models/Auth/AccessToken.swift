//
//  AccessToken.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// A short-lived bearer token for the Nebo API.
///
/// Dates are on the device clock, computed from the server's `expiresIn` at receipt, so a skewed clock does not
/// make the app refresh too late.
nonisolated struct AccessToken: Codable, Equatable, Sendable {

    let value: String

    let kind: AccessTokenKind

    /// When to get a new token ahead of time: a few minutes before ``expiresAt``.
    let refreshAfter: Date

    /// When the server stops accepting the token.
    let expiresAt: Date
}
