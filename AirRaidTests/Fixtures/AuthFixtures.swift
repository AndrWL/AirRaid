//
//  AuthFixtures.swift
//  AirRaidTests
//

import CryptoKit
import Foundation
@testable import AirRaid

// MARK: - ServerConfigDTO

extension ServerConfigDTO {

    /// A config signed the way the backend signs it: Ed25519 over `apiServerURL + "\n" + issuedAt`, base64url.
    static func signed(
        url: String,
        issuedAt: Int64,
        key: Curve25519.Signing.PrivateKey
    ) throws -> ServerConfigDTO {
        let signature = try key.signature(for: Data("\(url)\n\(issuedAt)".utf8))
        return ServerConfigDTO(apiServerURL: url, issuedAt: issuedAt, sig: signature.base64URLEncodedString())
    }
}

// MARK: - AccessTokenDTO

extension AccessTokenDTO {

    static func stub(
        accessToken: String = "token",
        expiresIn: Int = 3_600,
        kind: String? = "dev"
    ) -> AccessTokenDTO {
        AccessTokenDTO(accessToken: accessToken, expiresIn: expiresIn, kind: kind)
    }
}

// MARK: - AccessToken

extension AccessToken {

    /// A token as a previous launch left it; the times are offsets from the fixtures' origin.
    static func stub(
        value: String = "stored",
        kind: AccessTokenKind = .dev,
        refreshAfter: TimeInterval,
        expiresAt: TimeInterval
    ) -> AccessToken {
        AccessToken(
            value: value,
            kind: kind,
            refreshAfter: FeedFixtures.date(refreshAfter),
            expiresAt: FeedFixtures.date(expiresAt)
        )
    }
}

// MARK: - UserDefaults

extension UserDefaults {

    /// A suite name of the test's own, so it neither reads nor leaves anything in the app's defaults; remove it with
    /// `removePersistentDomain(forName:)` when done.
    static func makeIsolatedSuiteName() -> String {
        "AirRaidTests.\(UUID().uuidString)"
    }

    /// A fresh instance of the suite each call, so it can be handed to an actor: instances of one suite share their
    /// contents, which is what a relaunch test needs.
    static func isolated(_ suiteName: String) -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Could not create the defaults suite \(suiteName)")
        }
        return defaults
    }
}
