//
//  APIErrorDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// The backend's error body: `{"error":"<code>","message":"…"}`.
nonisolated struct APIErrorDTO: Decodable, Sendable {

    let error: String

    let message: String?

    /// Present with `upgrade_required` (426).
    let minVersion: String?
}
