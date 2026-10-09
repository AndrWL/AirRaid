//
//  AppAttestClientProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Apple's App Attest; exists so ``AuthService`` can be tested without DeviceCheck, which needs a real device.
nonisolated protocol AppAttestClientProtocol: Sendable {

    /// `false` on the simulator, in extensions, and on some managed devices.
    var isSupported: Bool { get }

    /// Creates a key pair in the Secure Enclave and returns its id. The key is lost when the app is deleted.
    func generateKey() async throws -> String

    /// Asks Apple to certify the key; `clientDataHash` binds the attestation to a server challenge.
    func attestKey(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data

    /// Signs `clientDataHash` with the key; Apple increments the key's counter on every call.
    func generateAssertion(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data
}
