//
//  KeychainService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Default ``KeychainServiceProtocol``: values are JSON-encoded into ``SecureStoring`` under private keys.
nonisolated struct KeychainService {

    // MARK: - Variables

    private let storage: SecureStoring
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    init(
        storage: SecureStoring = KeychainStorage()
    ) {
        self.storage = storage
    }
}

// MARK: - KeychainServiceProtocol

nonisolated extension KeychainService: KeychainServiceProtocol {

    var accessToken: AccessToken? {
        get {
            storage.data(for: Key.accessToken).flatMap { try? jsonDecoder.decode(AccessToken.self, from: $0) }
        }
        nonmutating set {
            storage.set(newValue.flatMap { try? jsonEncoder.encode($0) }, for: Key.accessToken)
        }
    }
}

// MARK: - Key

nonisolated private enum Key {
    static let accessToken = "accessToken"
}
