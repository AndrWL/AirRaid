//
//  KeychainStorage.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation
import Security

/// ``SecureStoring`` on generic-password Keychain items of this app.
///
/// Items are readable after the first unlock — the app reconnects in the background after a reboot — and
/// never leave the device (`ThisDeviceOnly`: not in backups, not restored to another phone).
nonisolated struct KeychainStorage {

    // MARK: - Variables

    private let service: String

    /// - Parameter service: Groups the items; the bundle identifier keeps Debug and Release builds apart.
    init(
        service: String = Bundle.main.bundleIdentifier ?? Constants.defaultService
    ) {
        self.service = service
    }
}

// MARK: - SecureStoring

nonisolated extension KeychainStorage: SecureStoring {

    func data(for key: String) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                assertionFailure("[KeychainStorage] Read failed: \(status)")
            }
            return nil
        }
        return result as? Data
    }

    func set(
        _ data: Data?,
        for key: String
    ) {
        let query = baseQuery(for: key)
        guard let data else {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess, status != errSecItemNotFound {
                assertionFailure("[KeychainStorage] Delete failed: \(status)")
            }
            return
        }

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        if status != errSecSuccess {
            assertionFailure("[KeychainStorage] Write failed: \(status)")
        }
    }
}

// MARK: - Private methods

nonisolated private extension KeychainStorage {

    func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let defaultService = "AirRaid"
}
