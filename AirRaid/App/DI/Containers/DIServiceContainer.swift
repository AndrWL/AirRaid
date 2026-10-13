//
//  DIServiceContainer.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import CryptoKit
import DependencyContainer
import Foundation
import WebSocketClient

/// DI container for service-layer dependencies (network, keychain, analytics, etc.).
///
/// Uses its own `DefaultDependencyContainer` instance internally.
/// Dependencies are registered in `assemble(with:)` and exposed through `DIServiceContaining` properties.
///
/// ## Lifetime guidelines
///
/// - `.singleton` — stateful or expensive services (network client, keychain, analytics).
/// - `.transient` — stateless or lightweight services.
final class DIServiceContainer {

    /// The underlying container that handles the actual registration and resolution of dependencies.
    private let container: DependencyContaining

    /// Initializes a new service dependency container.
    ///
    /// - Parameter container: The core container instance to use for dependency management.
    ///   Defaults to a new instance of ``DefaultDependencyContainer``.
    init(
        container: DependencyContaining = DefaultDependencyContainer()
    ) {
        self.container = container
    }
}

// MARK: - DIAssembling

extension DIServiceContainer: DIAssembling {

    func assemble(with appContainer: DIAppContaining) {
        registerUserAccessService()
        registerRealtimeVersionStore()
        registerServerAddressProvider()
        registerKeychainService()
        registerAuthTokenProvider()
        registerRealtimeService()
        registerUserLocationService()
        registerAlertSoundService()
    }
}

// MARK: - DIServiceContaining

extension DIServiceContainer: DIServiceContaining {

    var userAccessService: UserAccessServiceProtocol {
        return container.resolve(UserAccessServiceProtocol.self)
    }

    var realtimeService: RealtimeServiceProtocol {
        return container.resolve(RealtimeServiceProtocol.self)
    }

    var realtimeVersionStore: RealtimeVersionStore {
        return container.resolve(RealtimeVersionStore.self)
    }

    var userLocationService: UserLocationServiceProtocol {
        return container.resolve(UserLocationServiceProtocol.self)
    }

    var alertSoundService: AlertSoundServiceProtocol {
        return container.resolve(AlertSoundServiceProtocol.self)
    }
}

// MARK: - Configuration

private extension DIServiceContainer {

    func registerUserAccessService() {
        container.register(UserAccessServiceProtocol.self, lifetime: .singleton) { _ in
            UserAccessService()
        }
    }

    /// Shared by the WebSocket URL provider (reads) and the air situation repository (writes).
    func registerRealtimeVersionStore() {
        container.register(RealtimeVersionStore.self, lifetime: .singleton) { _ in
            RealtimeVersionStore()
        }
    }

    /// One instance, so every consumer sees the same address and concurrent attempts share one config fetch.
    func registerServerAddressProvider() {
        container.register(ServerAddressProviding.self, lifetime: .singleton) { _ in
            guard let configURL = URL(string: AppEnvironment.serverConfigURLString),
                  let keyData = Data(base64URLEncoded: AppEnvironment.serverConfigPublicKey),
                  let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
                fatalError("[DIServiceContainer] Invalid server config URL or public key in AppEnvironment")
            }
            return ServerConfigService(
                remoteDataSource: ServerConfigRemoteDataSource(configURL: configURL),
                publicKey: publicKey,
                allowedHostSuffixes: AppEnvironment.allowedServerHostSuffixes
            )
        }
    }

    func registerKeychainService() {
        container.register(KeychainServiceProtocol.self, lifetime: .singleton) { _ in
            KeychainService()
        }
    }

    /// One instance: it owns the single-flight token refresh that keeps App Attest counters in order.
    func registerAuthTokenProvider() {
        container.register(AuthTokenProviding.self, lifetime: .singleton) { resolver in
            AuthService(
                remoteDataSource: AuthRemoteDataSource(serverAddressProvider: resolver.resolve(ServerAddressProviding.self)),
                appAttestClient: AppAttestClient(),
                keychainService: resolver.resolve(KeychainServiceProtocol.self),
                devKey: AppEnvironment.devKey
            )
        }
    }

    func registerRealtimeService() {
        container.register(RealtimeServiceProtocol.self, lifetime: .singleton) { resolver in
            let versionStore = resolver.resolve(RealtimeVersionStore.self)
            let serverAddressProvider = resolver.resolve(ServerAddressProviding.self)
            let authTokenProvider = resolver.resolve(AuthTokenProviding.self)
            let client = WebSocketClient(
                configuration: WebSocketClientConfiguration(
                    // Rebuilt for every attempt: the server may have moved, and `since` moves on.
                    urlProvider: {
                        try RealtimeEndpoint.makeWebSocketURL(
                            serverURLString: try await serverAddressProvider.fetchServerURL().absoluteString,
                            since: versionStore.version
                        )
                    },
                    // Also per attempt, so a refreshed token is picked up on reconnect.
                    headersProvider: {
                        let token = try await authTokenProvider.fetchAccessToken()
                        return AppInfoHeaders.make().merging([Constants.authorization: "Bearer \(token)"]) { _, new in new }
                    },
                    // Not WebSocket ping frames: `URLSessionWebSocketTask` holds the pong behind the unread snapshot
                    // the server sends on connect. Any frame from the server proves the connection is alive.
                    heartbeat: .message(.text(RealtimeEndpoint.pingMessage)),
                    pingInterval: RealtimeEndpoint.pingInterval,
                    pongTimeout: RealtimeEndpoint.pongTimeout,
                    nonRetryableStatusCodes: [RealtimeEndpoint.upgradeRequiredStatusCode],
                    // Awaited before the retry, so the next attempt's headers carry new credentials.
                    failureHandler: { failure in
                        if let rejection = RealtimeAuthRejectionMapper.rejection(for: failure) {
                            await authTokenProvider.handleRejection(rejection)
                        }
                    }
                )
            )
            return RealtimeService(client: client)
        }
    }
}

// MARK: - Location

private extension DIServiceContainer {

    /// One instance: one location manager, one permission prompt.
    func registerUserLocationService() {
        container.register(UserLocationServiceProtocol.self, lifetime: .singleton) { _ in
            UserLocationService()
        }
    }

    func registerAlertSoundService() {
        container.register(AlertSoundServiceProtocol.self, lifetime: .transient) { _ in
            AlertSoundService()
        }
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let authorization = "Authorization"
}
