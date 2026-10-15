//
//  ServerConfigServiceTests.swift
//  AirRaidTests
//

import CryptoKit
import Foundation
import Testing
@testable import AirRaid

/// Tests for ``ServerConfigService``: where the app finds the API server.
///
/// Covers accepting only a signed config on an allowed host, refreshing at most once per 30 s but right after a
/// failure, keeping the last good address through failures and replays, the address surviving a relaunch (and a
/// tampered cached one not), and concurrent callers sharing one fetch.
@Suite(.timeLimit(.minutes(1)))
final class ServerConfigServiceTests {

    // MARK: - Variables

    private let remote = ServerConfigRemoteDataSourceSpy()
    private let clock = ClockSpy(Constants.start)
    private let signingKey = Curve25519.Signing.PrivateKey()
    private let defaultsSuiteName = UserDefaults.makeIsolatedSuiteName()

    deinit {
        UserDefaults.isolated(defaultsSuiteName).removePersistentDomain(forName: defaultsSuiteName)
    }

    // MARK: - fetchServerURL: checks

    @Test
    func fetchServerURL_whenConfigSignedAndHostAllowed_returnsAddress() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 100)))

        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.firstURL)
        #expect(remote.callCount == 1)
    }

    @Test
    func fetchServerURL_whenSignedByAnotherKey_throwsUnavailable() async throws {
        let sut = makeSUT()
        let forged = try ServerConfigDTO.signed(url: Constants.firstURL, issuedAt: 100, key: Curve25519.Signing.PrivateKey())
        await remote.respond(with: .success(forged))

        await #expect(throws: ServerConfigError.unavailable) { try await sut.fetchServerURL() }
    }

    @Test
    func fetchServerURL_whenSignedAddressOnForeignHost_throwsUnavailable() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(try config("https://alerts.example.com", issuedAt: 100)))

        await #expect(throws: ServerConfigError.unavailable) { try await sut.fetchServerURL() }
    }

    @Test
    func fetchServerURL_whenOfflineAndNothingCached_throwsUnavailable() async {
        let sut = makeSUT()
        await remote.respond(with: .failure(TestError.offline))

        await #expect(throws: ServerConfigError.unavailable) { try await sut.fetchServerURL() }
    }

    // MARK: - fetchServerURL: refresh interval

    @Test
    func fetchServerURL_whenAskedAgainWithin30Seconds_reusesAddressWithoutFetching() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 100)))
        _ = try await sut.fetchServerURL()
        clock.set(Constants.start.advanced(by: .seconds(30) - .milliseconds(1)))

        // No second response is prepared: a fetch here would hang until the time limit.
        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.firstURL)
        #expect(remote.callCount == 1)
    }

    @Test
    func fetchServerURL_when30SecondsPassed_fetchesAgainAndMovesToNewAddress() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 100)))
        _ = try await sut.fetchServerURL()
        clock.set(Constants.start.advanced(by: .seconds(30)))
        await remote.respond(with: .success(try config(Constants.secondURL, issuedAt: 200)))

        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.secondURL)
        #expect(remote.callCount == 2)
    }

    @Test
    func fetchServerURL_whenLastFetchFailed_retriesWithoutWaiting() async throws {
        let sut = makeSUT()
        await remote.respond(with: .failure(TestError.offline))
        _ = try? await sut.fetchServerURL()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 100)))

        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.firstURL)
        #expect(remote.callCount == 2)
    }

    // MARK: - fetchServerURL: keeping the last good address

    @Test(arguments: ServerConfigRefreshFailure.allCases)
    func fetchServerURL_whenRefreshFails_keepsLastAddress(failure: ServerConfigRefreshFailure) async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 100)))
        _ = try await sut.fetchServerURL()
        clock.set(Constants.start.advanced(by: .seconds(30)))
        await remote.respond(with: try failure.response(signingKey: signingKey))

        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.firstURL)
        #expect(remote.callCount == 2)
    }

    @Test
    func fetchServerURL_whenNewConfigIssuedEarlier_keepsCurrentAddress() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 200)))
        _ = try await sut.fetchServerURL()
        clock.set(Constants.start.advanced(by: .seconds(30)))
        await remote.respond(with: .success(try config(Constants.secondURL, issuedAt: 100)))

        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.firstURL)
    }

    // MARK: - Cache across launches

    @Test
    func fetchServerURL_whenRelaunchedOffline_returnsCachedAddress() async throws {
        let firstLaunch = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 100)))
        _ = try await firstLaunch.fetchServerURL()
        let sut = makeSUT()
        await remote.respond(with: .failure(TestError.offline))

        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.firstURL)
    }

    @Test
    func fetchServerURL_whenRelaunchedAndReplayedOlderConfig_keepsCachedAddress() async throws {
        let firstLaunch = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 200)))
        _ = try await firstLaunch.fetchServerURL()
        let sut = makeSUT()
        await remote.respond(with: .success(try config(Constants.secondURL, issuedAt: 100)))

        let url = try await sut.fetchServerURL()

        #expect(url.absoluteString == Constants.firstURL)
    }

    @Test
    func fetchServerURL_whenCachedAddressNotAllowed_ignoresIt() async throws {
        let otherBuild = makeSUT(allowedHostSuffixes: [".example.com"])
        await remote.respond(with: .success(try config("https://alerts.example.com", issuedAt: 100)))
        _ = try await otherBuild.fetchServerURL()
        let sut = makeSUT()
        await remote.respond(with: .failure(TestError.offline))

        await #expect(throws: ServerConfigError.unavailable) { try await sut.fetchServerURL() }
    }

    // MARK: - Concurrent callers

    @Test
    func fetchServerURL_whenCalledDuringFetch_sharesIt() async throws {
        let sut = makeSUT()
        await remote.respond(with: .success(try config(Constants.firstURL, issuedAt: 100)))
        _ = try await sut.fetchServerURL()
        try await remote.nextCall()
        clock.set(Constants.start.advanced(by: .seconds(30)))

        let first = Task { [sut] in try await sut.fetchServerURL() }
        defer { first.cancel() }
        try await remote.nextCall()
        let readsBeforeSecond = clock.readCount
        let second = Task { [sut] in try await sut.fetchServerURL() }
        defer { second.cancel() }
        // The second caller reads the clock to see the refresh is due, then joins the fetch without letting go of the
        // actor: once the read is seen, it is waiting for the first caller's fetch.
        try await clock.waitForReads(readsBeforeSecond + 1)
        await remote.respond(with: .success(try config(Constants.secondURL, issuedAt: 200)))

        #expect(try await first.value.absoluteString == Constants.secondURL)
        #expect(try await second.value.absoluteString == Constants.secondURL)
        #expect(remote.callCount == 2)
    }
}

// MARK: - Helpers

private extension ServerConfigServiceTests {

    func makeSUT(allowedHostSuffixes: [String] = [".trycloudflare.com"]) -> ServerConfigService {
        ServerConfigService(
            remoteDataSource: remote,
            publicKey: signingKey.publicKey,
            allowedHostSuffixes: allowedHostSuffixes,
            userDefaults: .isolated(defaultsSuiteName),
            now: { [clock] in clock.now() }
        )
    }

    func config(
        _ url: String,
        issuedAt: Int64
    ) throws -> ServerConfigDTO {
        try ServerConfigDTO.signed(url: url, issuedAt: issuedAt, key: signingKey)
    }
}

// MARK: - ServerConfigRefreshFailure

/// The ways a refresh can fail after a good address is known.
enum ServerConfigRefreshFailure: CaseIterable, Sendable {
    case offline
    case forgedSignature
    case foreignHost

    func response(signingKey: Curve25519.Signing.PrivateKey) throws -> Result<ServerConfigDTO, any Error> {
        switch self {
        case .offline:
            return .failure(TestError.offline)
        case .forgedSignature:
            let forgingKey = Curve25519.Signing.PrivateKey()
            return .success(try .signed(url: "https://forged.trycloudflare.com", issuedAt: 300, key: forgingKey))
        case .foreignHost:
            return .success(try .signed(url: "https://alerts.example.com", issuedAt: 300, key: signingKey))
        }
    }
}

// MARK: - ServerConfigRemoteDataSourceSpy

/// Reports every fetch and answers it with the next response the test sent; responses may be sent ahead.
final class ServerConfigRemoteDataSourceSpy: ServerConfigRemoteDataSourceProtocol {

    private let calls = AsyncQueue<Void>()
    private let responses = AsyncQueue<Result<ServerConfigDTO, any Error>>()
    private let count = LockIsolated(0)

    var callCount: Int {
        count.value
    }

    func fetchConfig() async throws -> ServerConfigDTO {
        count.withValue { $0 += 1 }
        await calls.send(())
        return try await responses.next().get()
    }

    /// Waits for the next fetch the test has not seen yet.
    func nextCall() async throws {
        try await calls.next()
    }

    func respond(with result: Result<ServerConfigDTO, any Error>) async {
        await responses.send(result)
    }
}

// MARK: - Constants

private enum Constants {
    static let start = ContinuousClock.now
    static let firstURL = "https://quiet-river-1234.trycloudflare.com"
    static let secondURL = "https://loud-sea-5678.trycloudflare.com"
}
