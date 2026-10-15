//
//  ServerConfigService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import CryptoKit
import Foundation
import OSLog

/// Default ``ServerAddressProviding``: the signed address from the config Worker, cached across launches.
///
/// The backend runs behind a quick tunnel whose address changes on every restart, so the address cannot be
/// compiled in. Each connection attempt asks for it; the config is fetched again at most once per
/// ``Constants/refreshInterval``, so a reconnecting client finds a moved server within a few attempts without
/// hammering the Worker. A failed fetch falls back to the last good address.
///
/// - Note: An `actor` because the WebSocket client's URL provider calls it off the main actor; concurrent callers
///   share one fetch.
actor ServerConfigService {

    // MARK: - Variables

    private let remoteDataSource: ServerConfigRemoteDataSourceProtocol
    private let publicKey: Curve25519.Signing.PublicKey
    private let allowedHostSuffixes: [String]
    private let userDefaults: UserDefaults
    private let now: @Sendable () -> ContinuousClock.Instant
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var config: ServerConfig?
    private var lastRefresh: ContinuousClock.Instant?
    private var refreshTask: Task<Void, Never>?

    /// - Parameters:
    ///   - remoteDataSource: Fetches the published config.
    ///   - publicKey: The backend's config-signing key.
    ///   - allowedHostSuffixes: Hosts the address may use; also re-checked for the cached address.
    ///   - userDefaults: Where the last good address survives a relaunch. Not a secret, so not Keychain.
    ///   - now: The monotonic clock the refresh interval is measured on; injected for tests.
    init(
        remoteDataSource: ServerConfigRemoteDataSourceProtocol,
        publicKey: Curve25519.Signing.PublicKey,
        allowedHostSuffixes: [String],
        userDefaults: UserDefaults = .standard,
        now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }
    ) {
        self.remoteDataSource = remoteDataSource
        self.publicKey = publicKey
        self.allowedHostSuffixes = allowedHostSuffixes
        self.userDefaults = userDefaults
        self.now = now
        config = Self.loadCachedConfig(from: userDefaults, allowedHostSuffixes: allowedHostSuffixes)
    }
}

// MARK: - ServerAddressProviding

extension ServerConfigService: ServerAddressProviding {

    func fetchServerURL() async throws -> URL {
        if isRefreshDue {
            await refresh()
        }
        guard let config else { throw ServerConfigError.unavailable }
        return config.apiServerURL
    }
}

// MARK: - Private methods

private extension ServerConfigService {

    var isRefreshDue: Bool {
        guard let lastRefresh else { return true }
        return now() - lastRefresh >= Constants.refreshInterval
    }

    /// Fetches and applies the config; concurrent callers await the same fetch.
    func refresh() async {
        if let refreshTask {
            await refreshTask.value
            return
        }
        let task = Task { await performRefresh() }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    func performRefresh() async {
        do {
            let dto = try await remoteDataSource.fetchConfig()
            let newConfig = try ServerConfigDTOMapper.toDomain(
                dto,
                publicKey: publicKey,
                allowedHostSuffixes: allowedHostSuffixes
            )
            apply(newConfig)
            // Only a valid answer counts: after a failure the next attempt tries again instead of waiting it out.
            lastRefresh = now()
        } catch {
            logger.error("Server config refresh failed: \(String(describing: error), privacy: .public)")
        }
    }

    func apply(_ newConfig: ServerConfig) {
        if let config, newConfig.issuedAt < config.issuedAt {
            logger.error("Ignored a server config older than the applied one (replay?)")
            return
        }
        guard newConfig != config else { return }
        logger.info("Server address: \(newConfig.apiServerURL.absoluteString, privacy: .public)")
        config = newConfig
        userDefaults.set(newConfig.apiServerURL.absoluteString, forKey: Key.apiServerURL)
        userDefaults.set(newConfig.issuedAt, forKey: Key.issuedAt)
    }

    static func loadCachedConfig(
        from userDefaults: UserDefaults,
        allowedHostSuffixes: [String]
    ) -> ServerConfig? {
        guard let urlString = userDefaults.string(forKey: Key.apiServerURL),
              let url = try? ServerConfigDTOMapper.validatedURL(urlString, allowedHostSuffixes: allowedHostSuffixes) else {
            return nil
        }
        let issuedAt = (userDefaults.object(forKey: Key.issuedAt) as? NSNumber)?.int64Value ?? 0
        return ServerConfig(apiServerURL: url, issuedAt: issuedAt)
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "ServerConfig"
    /// Matches the Worker's `Cache-Control: max-age=30`: refreshing more often would only hit the cache.
    static let refreshInterval: Duration = .seconds(30)
}

nonisolated private enum Key {
    static let apiServerURL = "serverConfig.apiServerURL"
    static let issuedAt = "serverConfig.issuedAt"
}
