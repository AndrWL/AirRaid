//
//  AuthService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import CryptoKit
import DeviceCheck
import Foundation
import OSLog

/// Default ``AuthTokenProviding``: App Attest installations and short-lived bearer tokens from the Nebo API.
///
/// ## Getting a token
///
/// - **Simulator** (a developer key is set): `/v1/dev/token`; App Attest does not work there.
/// - **Attested key on file**: challenge → assertion → `/v1/auth/token`.
/// - **No key yet**, or the server lost/revoked it: new key → challenge → attestation → `/v1/auth/attest`.
/// - **Attestation impossible now** (unsupported device, Apple unavailable, backoff): `/v1/token/unattested`,
///   a limited token; the next refresh tries to attest again.
///
/// ## Limits that protect the backend
///
/// Concurrent callers (WebSocket, later REST) share one refresh, so App Attest counters never race.
/// A `challenge_invalid` gets one retry with a new challenge. At most one new key per launch, and failed
/// attestations back off (1 min → 6 h) across launches, so a crash loop cannot flood `/attest`.
/// Network and server errors never discard a key.
actor AuthService {

    // MARK: - Variables

    private let remoteDataSource: AuthRemoteDataSourceProtocol
    private let appAttestClient: AppAttestClientProtocol
    private let keychainService: KeychainServiceProtocol
    private let userDefaults: UserDefaults
    private let devKey: String?
    private let now: @Sendable () -> Date
    private let jsonEncoder: JSONEncoder
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var token: AccessToken?
    private var refreshTask: Task<AccessToken, Error>?
    private var didGenerateKeyThisLaunch = false

    /// - Parameters:
    ///   - remoteDataSource: The auth endpoints.
    ///   - appAttestClient: Apple's App Attest.
    ///   - keychainService: Keeps the token across launches.
    ///   - userDefaults: Keeps the key id and the attestation backoff. The key id is not a secret, and unlike
    ///     the Keychain, defaults are deleted with the app — together with the Secure Enclave key they point to.
    ///   - devKey: The developer key for `/v1/dev/token`; non-`nil` only in simulator builds.
    ///   - now: The clock; injected for tests.
    init(
        remoteDataSource: AuthRemoteDataSourceProtocol,
        appAttestClient: AppAttestClientProtocol,
        keychainService: KeychainServiceProtocol,
        userDefaults: UserDefaults = .standard,
        devKey: String?,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.remoteDataSource = remoteDataSource
        self.appAttestClient = appAttestClient
        self.keychainService = keychainService
        self.userDefaults = userDefaults
        self.devKey = devKey
        self.now = now
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        self.jsonEncoder = jsonEncoder
        token = keychainService.accessToken
    }
}

// MARK: - AuthTokenProviding

extension AuthService: AuthTokenProviding {

    func fetchAccessToken() async throws -> String {
        if let token, now() < token.refreshAfter {
            return token.value
        }
        do {
            return try await refresh().value
        } catch {
            // A failed early refresh is no reason to drop a token the server still accepts.
            if let token, now() < token.expiresAt {
                logger.error("Token refresh failed, keeping the current one: \(String(describing: error), privacy: .public)")
                return token.value
            }
            throw error
        }
    }

    func handleRejection(_ rejection: AuthRejection) async {
        logger.info("Credentials rejected: \(String(describing: rejection), privacy: .public)")
        save(nil)
        if rejection == .installationRevoked {
            forgetKey()
        }
    }
}

// MARK: - Private methods

private extension AuthService {

    /// Runs one ``obtainToken()`` for all concurrent callers.
    func refresh() async throws -> AccessToken {
        if let refreshTask {
            return try await refreshTask.value
        }
        let task = Task { try await obtainToken() }
        refreshTask = task
        do {
            let newToken = try await task.value
            refreshTask = nil
            save(newToken)
            logger.info("New \(newToken.kind.rawValue, privacy: .public) token")
            return newToken
        } catch {
            refreshTask = nil
            logger.error("Token request failed: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    func obtainToken() async throws -> AccessToken {
        if let devKey {
            return try await map(remoteDataSource.fetchDevToken(devKey: devKey))
        }
        guard appAttestClient.isSupported else {
            return try await map(remoteDataSource.fetchUnattestedToken())
        }
        if let keyId = attestedKeyId {
            do {
                return try await fetchTokenWithAssertion(keyId: keyId)
            } catch where Self.isKeyUnusable(error) {
                logger.error("Attested key unusable, attesting a new one: \(String(describing: error), privacy: .public)")
                forgetKey()
            }
        }
        do {
            return try await attestInstallation()
        } catch where Self.allowsUnattestedFallback(error) {
            logger.error("Attestation unavailable, using a limited token: \(String(describing: error), privacy: .public)")
            return try await map(remoteDataSource.fetchUnattestedToken())
        }
    }

    func fetchTokenWithAssertion(keyId: String) async throws -> AccessToken {
        try await withChallenge { clientData in
            let assertion = try await appAttestClient.generateAssertion(keyId, clientDataHash: Self.hash(clientData))
            return try await remoteDataSource.fetchToken(TokenRequestDTO(
                keyId: keyId,
                clientData: clientData.base64URLEncodedString(),
                assertion: assertion.base64URLEncodedString()
            ))
        }
    }

    func attestInstallation() async throws -> AccessToken {
        if let nextAttestAt, now() < nextAttestAt {
            throw AuthServiceError.attestationDeferred(until: nextAttestAt)
        }
        let keyId = try await keyForAttestation()
        do {
            let newToken = try await withChallenge { clientData in
                let attestation = try await appAttestClient.attestKey(keyId, clientDataHash: Self.hash(clientData))
                return try await remoteDataSource.attest(AttestRequestDTO(
                    keyId: keyId,
                    attestation: attestation.base64URLEncodedString(),
                    clientData: clientData.base64URLEncodedString()
                ))
            }
            markAttested(keyId)
            return newToken
        } catch let error as AuthAPIError where error.code == AuthAPIError.Code.keyAlreadyAttested {
            // The server registered the key, but the answer was lost: the key is good for assertions.
            markAttested(keyId)
            return try await fetchTokenWithAssertion(keyId: keyId)
        } catch {
            recordAttestationFailure(error)
            throw error
        }
    }

    /// The key to attest: one generated earlier whose attestation did not finish, or a new one (once per launch).
    func keyForAttestation() async throws -> String {
        if let pendingKeyId {
            return pendingKeyId
        }
        guard !didGenerateKeyThisLaunch else { throw AuthServiceError.attestationDeferred(until: nil) }
        didGenerateKeyThisLaunch = true
        let keyId = try await appAttestClient.generateKey()
        userDefaults.set(keyId, forKey: Key.keyId)
        userDefaults.set(false, forKey: Key.isKeyAttested)
        return keyId
    }

    /// Runs `operation` with fresh client data; a `challenge_invalid` (expired or reused) gets one retry.
    func withChallenge(_ operation: (Data) async throws -> AccessTokenDTO) async throws -> AccessToken {
        for attempt in 1...Constants.challengeAttempts {
            let challenge = try await remoteDataSource.fetchChallenge()
            let clientData = try jsonEncoder.encode(ClientDataDTO(challenge: challenge.challenge))
            do {
                return try await map(operation(clientData))
            } catch let error as AuthAPIError
                where error.code == AuthAPIError.Code.challengeInvalid && attempt < Constants.challengeAttempts {
                continue
            }
        }
        throw AuthServiceError.challengeRejected
    }

    func map(_ dto: AccessTokenDTO) -> AccessToken {
        AccessTokenDTOMapper.toDomain(dto, receivedAt: now())
    }

    func save(_ newToken: AccessToken?) {
        token = newToken
        keychainService.accessToken = newToken
    }

    static func hash(_ clientData: Data) -> Data {
        Data(SHA256.hash(data: clientData))
    }
}

// MARK: - Key and backoff state

private extension AuthService {

    var attestedKeyId: String? {
        userDefaults.bool(forKey: Key.isKeyAttested) ? userDefaults.string(forKey: Key.keyId) : nil
    }

    var pendingKeyId: String? {
        userDefaults.bool(forKey: Key.isKeyAttested) ? nil : userDefaults.string(forKey: Key.keyId)
    }

    var nextAttestAt: Date? {
        userDefaults.object(forKey: Key.nextAttestAt) as? Date
    }

    func markAttested(_ keyId: String) {
        userDefaults.set(keyId, forKey: Key.keyId)
        userDefaults.set(true, forKey: Key.isKeyAttested)
        userDefaults.removeObject(forKey: Key.attestFailures)
        userDefaults.removeObject(forKey: Key.nextAttestAt)
    }

    func forgetKey() {
        userDefaults.removeObject(forKey: Key.keyId)
        userDefaults.removeObject(forKey: Key.isKeyAttested)
    }

    /// Schedules the next attestation and drops the key when Apple or the server says it can never pass.
    func recordAttestationFailure(_ error: Error) {
        if Self.isKeyUnusable(error) || (error as? AuthAPIError)?.code == AuthAPIError.Code.attestationInvalid {
            forgetKey()
        }
        let failures = userDefaults.integer(forKey: Key.attestFailures) + 1
        userDefaults.set(failures, forKey: Key.attestFailures)
        let backoff = Constants.attestBackoff[min(failures, Constants.attestBackoff.count) - 1]
        let delay = max(backoff, (error as? AuthAPIError)?.retryAfter ?? 0)
        userDefaults.set(now().addingTimeInterval(delay), forKey: Key.nextAttestAt)
        logger.error("Attestation failed (\(failures)), next try in \(Int(delay)) s: \(String(describing: error), privacy: .public)")
    }

    /// The key itself is the problem: retrying with it cannot succeed.
    static func isKeyUnusable(_ error: Error) -> Bool {
        if let error = error as? DCError {
            return error.code == .invalidKey || error.code == .invalidInput
        }
        guard let code = (error as? AuthAPIError)?.code else { return false }
        return [
            AuthAPIError.Code.installationUnknown,
            AuthAPIError.Code.installationRevoked,
            AuthAPIError.Code.assertionInvalid
        ].contains(code)
    }

    /// A limited token beats no data in an alerts app — unless the network is down (it would fail too) or
    /// the app is too old (the server refuses every token).
    static func allowsUnattestedFallback(_ error: Error) -> Bool {
        if error is URLError {
            return false
        }
        return (error as? AuthAPIError)?.code != AuthAPIError.Code.upgradeRequired
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Auth"
    static let challengeAttempts = 2
    /// 1 min, 5 min, 30 min, then every 6 h.
    static let attestBackoff: [TimeInterval] = [60, 5 * 60, 30 * 60, 6 * 60 * 60]
}

nonisolated private enum Key {
    static let keyId = "auth.keyId"
    static let isKeyAttested = "auth.isKeyAttested"
    static let attestFailures = "auth.attestFailures"
    static let nextAttestAt = "auth.nextAttestAt"
}
