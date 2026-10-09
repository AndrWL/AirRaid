//
//  SecureStoring.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// A raw key-value store for secrets. Consumers use ``KeychainServiceProtocol``, never this directly.
nonisolated protocol SecureStoring: Sendable {

    func data(for key: String) -> Data?

    /// Stores `data`, or removes the item when `data` is `nil`.
    func set(
        _ data: Data?,
        for key: String
    )
}
