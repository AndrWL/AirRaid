//
//  AppAttestClient.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import DeviceCheck
import Foundation

/// ``AppAttestClientProtocol`` on top of `DCAppAttestService.shared`.
nonisolated struct AppAttestClient {}

// MARK: - AppAttestClientProtocol

nonisolated extension AppAttestClient: AppAttestClientProtocol {

    var isSupported: Bool {
        DCAppAttestService.shared.isSupported
    }

    func generateKey() async throws -> String {
        try await DCAppAttestService.shared.generateKey()
    }

    func attestKey(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data {
        try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)
    }

    func generateAssertion(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data {
        try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash)
    }
}
