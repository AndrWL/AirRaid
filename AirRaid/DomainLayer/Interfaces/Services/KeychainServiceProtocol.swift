//
//  KeychainServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Typed access to the secrets the app keeps in the Keychain.
nonisolated protocol KeychainServiceProtocol: Sendable {

    /// The last API token, kept across launches so a cold start does not need a new one; `nil` removes it.
    var accessToken: AccessToken? { get nonmutating set }
}
