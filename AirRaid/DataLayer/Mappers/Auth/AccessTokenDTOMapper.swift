//
//  AccessTokenDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

nonisolated enum AccessTokenDTOMapper {

    /// - Parameter receivedAt: When the response arrived; the lifetime is counted from it on the device clock.
    static func toDomain(
        _ dto: AccessTokenDTO,
        receivedAt: Date
    ) -> AccessToken {
        let lifetime = TimeInterval(max(dto.expiresIn, 0))
        // Five minutes ahead for the usual hour-long token; a tenth of the lifetime for a short one.
        let refreshMargin = min(Constants.maxRefreshMargin, lifetime / Constants.shortLifetimeDivisor)
        return AccessToken(
            value: dto.accessToken,
            kind: dto.kind.flatMap(AccessTokenKind.init(rawValue:)) ?? .attested,
            refreshAfter: receivedAt.addingTimeInterval(lifetime - refreshMargin),
            expiresAt: receivedAt.addingTimeInterval(lifetime)
        )
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let maxRefreshMargin: TimeInterval = 5 * 60
    static let shortLifetimeDivisor: TimeInterval = 10
}
