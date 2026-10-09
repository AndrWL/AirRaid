//
//  AccessTokenKind.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// How the backend vouched for the installation that holds a token.
nonisolated enum AccessTokenKind: String, Codable, Sendable {

    /// App Attest verified the app and the device.
    case attested

    /// Simulator builds: issued for the developer key, App Attest skipped.
    case dev

    /// The device could not attest (unsupported, or Apple unavailable). Works with a stricter rate limit and
    /// without some endpoints; the app tries to attest again on the next refresh.
    case unattested
}
