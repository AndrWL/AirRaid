//
//  AccessTokenDTOMapperTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``AccessTokenDTOMapper``: when the app refreshes a token.
///
/// Covers the five-minute margin for the usual hour-long token, a tenth of the lifetime for a short one, a
/// nonsensical lifetime, and the token kind's fallback.
@Suite
struct AccessTokenDTOMapperTests {

    // MARK: - toDomain

    @Test(arguments: [
        (3_600, 3_300.0),
        (7_200, 6_900.0),
        (600, 540.0),
        (60, 54.0),
        (0, 0.0),
        (-100, 0.0)
    ])
    func toDomain_whenLifetimeGiven_refreshesFiveMinutesOrATenthEarly(expiresIn: Int, refreshAfter: TimeInterval) {
        let token = AccessTokenDTOMapper.toDomain(.stub(expiresIn: expiresIn), receivedAt: FeedFixtures.origin)

        #expect(token.refreshAfter == FeedFixtures.date(refreshAfter))
        #expect(token.expiresAt == FeedFixtures.date(TimeInterval(max(expiresIn, 0))))
    }

    @Test(arguments: [
        (String?.some("attested"), AccessTokenKind.attested),
        ("dev", .dev),
        ("unattested", .unattested),
        (nil, .attested),
        ("premium", .attested)
    ])
    func toDomain_whenKind_mapsOrFallsBackToAttested(kind: String?, expected: AccessTokenKind) {
        let token = AccessTokenDTOMapper.toDomain(.stub(accessToken: "abc", kind: kind), receivedAt: FeedFixtures.origin)

        #expect(token.kind == expected)
        #expect(token.value == "abc")
    }
}
