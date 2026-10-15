//
//  AuthServiceTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``AuthService/fetchAccessToken()`` and ``AuthService/handleRejection(_:)`` on the developer-key path
/// (the simulator's), where getting a token is one request.
///
/// Covers reusing a fresh token, refreshing five minutes before expiry, concurrent callers sharing one request (also
/// when it fails, after which the next call tries again), keeping a still-valid token when an early refresh fails, and
/// dropping a rejected one.
@Suite(.timeLimit(.minutes(1)))
final class AuthServiceTests {

    // MARK: - Variables

    private let remote = AuthRemoteDataSourceSpy()
    private let keychain = KeychainServiceStub()
    private let clock = ClockSpy(Constants.start)
    private let defaultsSuiteName = UserDefaults.makeIsolatedSuiteName()

    deinit {
        UserDefaults.isolated(defaultsSuiteName).removePersistentDomain(forName: defaultsSuiteName)
    }

    // MARK: - fetchAccessToken: getting and reusing a token

    @Test
    func fetchAccessToken_whenNoToken_requestsOneWithDevKeyAndSavesIt() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(.stub(accessToken: "new", expiresIn: 3_600, kind: "dev")))

        let token = try await sut.fetchAccessToken()

        #expect(token == "new")
        #expect(try await remote.nextCall() == Constants.devKey)
        #expect(keychain.accessToken == AccessToken(
            value: "new",
            kind: .dev,
            refreshAfter: Constants.start.addingTimeInterval(3_300),
            expiresAt: Constants.start.addingTimeInterval(3_600)
        ))
    }

    @Test
    func fetchAccessToken_whenStoredTokenFresh_returnsItWithoutRequest() async throws {
        keychain.accessToken = .stub(value: "stored", refreshAfter: 60, expiresAt: 360)
        let sut = makeSUT()

        let token = try await sut.fetchAccessToken()

        #expect(token == "stored")
        #expect(remote.callCount == 0)
    }

    @Test
    func fetchAccessToken_whenFiveMinutesBeforeExpiry_refreshes() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(.stub(accessToken: "first", expiresIn: 3_600)))
        _ = try await sut.fetchAccessToken()

        clock.set(Constants.start.addingTimeInterval(3_300 - 1))
        let beforeMargin = try await sut.fetchAccessToken()
        clock.set(Constants.start.addingTimeInterval(3_300))
        await remote.respond(with: .success(.stub(accessToken: "second", expiresIn: 3_600)))
        let atMargin = try await sut.fetchAccessToken()

        #expect(beforeMargin == "first")
        #expect(atMargin == "second")
        #expect(remote.callCount == 2)
    }

    // MARK: - fetchAccessToken: concurrent callers

    @Test
    func fetchAccessToken_whenCalledDuringRefresh_sharesOneRequest() async throws {
        keychain.accessToken = .stub(refreshAfter: -1, expiresAt: 299)
        let sut = makeSUT()

        let first = Task { [sut] in try await sut.fetchAccessToken() }
        defer { first.cancel() }
        _ = try await remote.nextCall()
        let readsBeforeSecond = clock.readCount
        let second = Task { [sut] in try await sut.fetchAccessToken() }
        defer { second.cancel() }
        // The second caller reads the clock to see the token is due, then joins the refresh without letting go of the
        // actor: once the read is seen, it is waiting for the first caller's request.
        try await clock.waitForReads(readsBeforeSecond + 1)
        await remote.respond(with: .success(.stub(accessToken: "new")))

        #expect(try await first.value == "new")
        #expect(try await second.value == "new")
        #expect(remote.callCount == 1)
    }

    @Test
    func fetchAccessToken_whenSharedRequestFails_failsBothAndNextCallTriesAgain() async throws {
        keychain.accessToken = .stub(refreshAfter: -600, expiresAt: -1)
        let sut = makeSUT()

        let first = Task { [sut] in try await sut.fetchAccessToken() }
        defer { first.cancel() }
        _ = try await remote.nextCall()
        let readsBeforeSecond = clock.readCount
        let second = Task { [sut] in try await sut.fetchAccessToken() }
        defer { second.cancel() }
        try await clock.waitForReads(readsBeforeSecond + 1)
        await remote.respond(with: .failure(TestError.offline))

        await #expect(throws: TestError.offline) { try await first.value }
        await #expect(throws: TestError.offline) { try await second.value }
        #expect(remote.callCount == 1)

        await remote.respond(with: .success(.stub(accessToken: "new")))
        let token = try await sut.fetchAccessToken()

        #expect(token == "new")
        #expect(remote.callCount == 2)
    }

    // MARK: - fetchAccessToken: failed refresh

    @Test
    func fetchAccessToken_whenEarlyRefreshFails_keepsCurrentToken() async throws {
        let stored = AccessToken.stub(value: "stored", refreshAfter: -1, expiresAt: 299)
        keychain.accessToken = stored
        let sut = makeSUT()
        await remote.respond(with: .failure(TestError.offline))

        let token = try await sut.fetchAccessToken()

        #expect(token == "stored")
        #expect(keychain.accessToken == stored)
    }

    @Test
    func fetchAccessToken_whenRefreshFailsAfterExpiry_throws() async {
        keychain.accessToken = .stub(refreshAfter: -300, expiresAt: 0)
        let sut = makeSUT()
        await remote.respond(with: .failure(TestError.offline))

        await #expect(throws: TestError.offline) { try await sut.fetchAccessToken() }
    }

    // MARK: - handleRejection

    @Test(arguments: [AuthRejection.tokenRejected, .installationRevoked])
    func handleRejection_whenTokenRefused_dropsItSoNextCallRequestsNew(rejection: AuthRejection) async throws {
        keychain.accessToken = .stub(value: "stored", refreshAfter: 60, expiresAt: 360)
        let sut = makeSUT()

        await sut.handleRejection(rejection)
        await remote.respond(with: .success(.stub(accessToken: "new")))
        let token = try await sut.fetchAccessToken()

        #expect(token == "new")
        #expect(keychain.accessToken?.value == "new")
        #expect(remote.callCount == 1)
    }
}

// MARK: - Helpers

private extension AuthServiceTests {

    func makeSUT() -> AuthService {
        AuthService(
            remoteDataSource: remote,
            appAttestClient: AppAttestClientStub(),
            keychainService: keychain,
            userDefaults: .isolated(defaultsSuiteName),
            devKey: Constants.devKey,
            now: { [clock] in clock.now() }
        )
    }
}

// MARK: - AuthRemoteDataSourceSpy

/// Reports every developer-token request and answers it with the next response the test sent; responses may be sent
/// ahead. The App Attest endpoints are not expected on this path and fail.
final class AuthRemoteDataSourceSpy: AuthRemoteDataSourceProtocol {

    private let calls = AsyncQueue<String>()
    private let responses = AsyncQueue<Result<AccessTokenDTO, any Error>>()
    private let count = LockIsolated(0)

    /// How many developer tokens were requested.
    var callCount: Int {
        count.value
    }

    func fetchDevToken(devKey: String) async throws -> AccessTokenDTO {
        count.withValue { $0 += 1 }
        await calls.send(devKey)
        return try await responses.next().get()
    }

    /// Waits for the next developer-token request the test has not seen yet; returns its key.
    func nextCall() async throws -> String {
        try await calls.next()
    }

    func respond(with result: Result<AccessTokenDTO, any Error>) async {
        await responses.send(result)
    }

    func fetchChallenge() async throws -> ChallengeDTO {
        throw TestError.unexpectedCall
    }

    func attest(_ request: AttestRequestDTO) async throws -> AccessTokenDTO {
        throw TestError.unexpectedCall
    }

    func fetchToken(_ request: TokenRequestDTO) async throws -> AccessTokenDTO {
        throw TestError.unexpectedCall
    }

    func fetchUnattestedToken() async throws -> AccessTokenDTO {
        throw TestError.unexpectedCall
    }
}

// MARK: - AppAttestClientStub

/// A device without App Attest; never called on the developer-key path.
struct AppAttestClientStub: AppAttestClientProtocol {

    var isSupported: Bool {
        false
    }

    func generateKey() async throws -> String {
        throw TestError.unexpectedCall
    }

    func attestKey(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data {
        throw TestError.unexpectedCall
    }

    func generateAssertion(
        _ keyId: String,
        clientDataHash: Data
    ) async throws -> Data {
        throw TestError.unexpectedCall
    }
}

// MARK: - KeychainServiceStub

/// An in-memory Keychain.
final class KeychainServiceStub: KeychainServiceProtocol {

    private let storage = LockIsolated<AccessToken?>(nil)

    var accessToken: AccessToken? {
        get { storage.value }
        set { storage.withValue { $0 = newValue } }
    }
}

// MARK: - Constants

private enum Constants {
    static let start = FeedFixtures.origin
    static let devKey = "dev-key"
}
