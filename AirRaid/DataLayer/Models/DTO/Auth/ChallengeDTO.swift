//
//  ChallengeDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// `POST /v1/auth/challenge` response. Single use; valid for `expiresIn` seconds.
nonisolated struct ChallengeDTO: Decodable, Sendable {

    let challenge: String
}
