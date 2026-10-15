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
        registerNotificationPermissionService()
        registerLiveActivitySettingsService()
        registerHomeStatusBroadcaster(with: appContainer)
        registerEntitlementService()
        registerWatchedPlacesProvider(with: appContainer)
        registerWatchedRegionsProvider(with: appContainer)
        registerVoiceSettingsService()
        registerSpeechService()
        registerFeedVoiceAnnouncer(with: appContainer)
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

    var notificationPermissionService: NotificationPermissionServiceProtocol {
        return container.resolve(NotificationPermissionServiceProtocol.self)
    }

    var liveActivitySettingsService: LiveActivitySettingsServiceProtocol {
        return container.resolve(LiveActivitySettingsServiceProtocol.self)
    }

    var homeStatusBroadcaster: HomeStatusBroadcasting {
        return container.resolve(HomeStatusBroadcasting.self)
    }

    var watchedPlacesProvider: WatchedPlacesProviding {
        return container.resolve(WatchedPlacesProviding.self)
    }

    var watchedRegionsProvider: WatchedRegionsProviding {
        return container.resolve(WatchedRegionsProviding.self)
    }

    var entitlementService: EntitlementServiceProtocol {
        return container.resolve(EntitlementServiceProtocol.self)
    }

    var voiceSettingsService: VoiceSettingsServiceProtocol {
        return container.resolve(VoiceSettingsServiceProtocol.self)
    }

    var speechService: SpeechServiceProtocol {
        return container.resolve(SpeechServiceProtocol.self)
    }

    var feedVoiceAnnouncer: FeedVoiceAnnouncing {
        return container.resolve(FeedVoiceAnnouncing.self)
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

// MARK: - Device

private extension DIServiceContainer {

    /// One instance: one location manager, one permission prompt.
    func registerUserLocationService() {
        container.register(UserLocationServiceProtocol.self, lifetime: .singleton) { _ in
            UserLocationService()
        }
    }

    /// A singleton so the map plays in the mode the settings just picked.
    func registerAlertSoundService() {
        container.register(AlertSoundServiceProtocol.self, lifetime: .singleton) { _ in
            AlertSoundService()
        }
    }

    func registerNotificationPermissionService() {
        container.register(NotificationPermissionServiceProtocol.self, lifetime: .transient) { _ in
            NotificationPermissionService()
        }
    }
}

// MARK: - System surfaces

private extension DIServiceContainer {

    /// A singleton so the broadcaster hears the switch the settings just flipped.
    func registerLiveActivitySettingsService() {
        container.register(LiveActivitySettingsServiceProtocol.self, lifetime: .singleton) { _ in
            LiveActivitySettingsService()
        }
    }

    /// One instance: it owns the single Live Activity and the widget's last snapshot. Resolves repositories lazily,
    /// so registering it before the repository container is assembled is fine.
    func registerHomeStatusBroadcaster(with appContainer: DIAppContaining) {
        container.register(HomeStatusBroadcasting.self, lifetime: .singleton) { resolver in
            let repositories = appContainer.repositories
            return HomeStatusBroadcaster(
                realtimeService: resolver.resolve(RealtimeServiceProtocol.self),
                airSituationRepository: repositories.airSituationRepository,
                placeSettingsRepository: repositories.placeSettingsRepository,
                userLocationService: resolver.resolve(UserLocationServiceProtocol.self),
                regionBoundaryRepository: repositories.regionBoundaryRepository,
                districtBoundaryRepository: repositories.districtBoundaryRepository,
                widgetPublisher: HomeWidgetPublisher(),
                activityController: HomeAlertActivityController(),
                liveActivitySettingsService: resolver.resolve(LiveActivitySettingsServiceProtocol.self)
            )
        }
    }
}

// MARK: - Feed

private extension DIServiceContainer {

    /// A singleton so the map, the feed and the voice watch the same places. Resolves repositories lazily.
    func registerWatchedPlacesProvider(with appContainer: DIAppContaining) {
        container.register(WatchedPlacesProviding.self, lifetime: .singleton) { resolver in
            WatchedPlacesService(
                placeSettingsRepository: appContainer.repositories.placeSettingsRepository,
                userLocationService: resolver.resolve(UserLocationServiceProtocol.self),
                entitlementService: resolver.resolve(EntitlementServiceProtocol.self)
            )
        }
    }

    /// A singleton so the feed and the voice filter by the same places. Resolves repositories lazily.
    func registerWatchedRegionsProvider(with appContainer: DIAppContaining) {
        container.register(WatchedRegionsProviding.self, lifetime: .singleton) { resolver in
            WatchedRegionsService(
                watchedPlacesProvider: resolver.resolve(WatchedPlacesProviding.self),
                regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository
            )
        }
    }

    /// One instance: it owns the single listener for App Store transactions.
    func registerEntitlementService() {
        container.register(EntitlementServiceProtocol.self, lifetime: .singleton) { _ in
            StoreKitEntitlementService(productIDs: Set(AppEnvironment.plusProductIDs))
        }
    }

    /// A singleton so the voice reads by the rules the settings just changed.
    func registerVoiceSettingsService() {
        container.register(VoiceSettingsServiceProtocol.self, lifetime: .singleton) { _ in
            VoiceSettingsService()
        }
    }

    /// One instance: one synthesizer, one queue, so two screens never talk over each other.
    func registerSpeechService() {
        container.register(SpeechServiceProtocol.self, lifetime: .singleton) { _ in
            SpeechService()
        }
    }

    /// One instance: the voice feed keeps playing while the user switches tabs.
    func registerFeedVoiceAnnouncer(with appContainer: DIAppContaining) {
        container.register(FeedVoiceAnnouncing.self, lifetime: .singleton) { resolver in
            FeedVoiceAnnouncer(
                feedRepository: appContainer.repositories.feedRepository,
                airSituationRepository: appContainer.repositories.airSituationRepository,
                watchedPlacesProvider: resolver.resolve(WatchedPlacesProviding.self),
                watchedRegionsProvider: resolver.resolve(WatchedRegionsProviding.self),
                dependencies: FeedVoiceAnnouncer.Dependencies(
                    speechService: resolver.resolve(SpeechServiceProtocol.self),
                    voiceSettingsService: resolver.resolve(VoiceSettingsServiceProtocol.self),
                    entitlementService: resolver.resolve(EntitlementServiceProtocol.self),
                    alertSoundService: resolver.resolve(AlertSoundServiceProtocol.self)
                )
            )
        }
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let authorization = "Authorization"
}
