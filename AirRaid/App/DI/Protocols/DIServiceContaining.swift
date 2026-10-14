//
//  DIServiceContaining.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// Public API for resolving service-layer dependencies.
///
/// Consumers (ViewModels, UseCases) depend on this protocol — not on `DIServiceContainer` directly.
/// This ensures that `assemble(with:)` is hidden and only resolved dependencies are accessible.
///
/// ## Adding a new service dependency
///
/// 1. Register the dependency in `DIServiceContainer.assemble(with:)`:
///    ```swift
///    container.register(AnalyticsServiceProtocol.self, lifetime: .singleton) { _ in
///        AnalyticsService()
///    }
///    ```
/// 2. Expose it as a computed property in this protocol:
///    ```swift
///    protocol DIServiceContaining {
///        var analyticsService: AnalyticsServiceProtocol { get }
///    }
///    ```
/// 3. Implement the property in `DIServiceContainer`:
///    ```swift
///    var analyticsService: AnalyticsServiceProtocol {
///        container.resolve(AnalyticsServiceProtocol.self)
///    }
///    ```
protocol DIServiceContaining {

    /// The service responsible for tracking and managing the user's access state
    /// (e.g., authenticated, unauthenticated, requires onboarding).
    var userAccessService: UserAccessServiceProtocol { get }

    /// The live WebSocket connection to the backend.
    var realtimeService: RealtimeServiceProtocol { get }

    /// The last applied server version, for resuming the realtime stream with `since`.
    var realtimeVersionStore: RealtimeVersionStore { get }

    /// The user's location while the app is in use.
    var userLocationService: UserLocationServiceProtocol { get }

    /// The app's alert sounds while it is open, and the mode they play in.
    var alertSoundService: AlertSoundServiceProtocol { get }

    /// The permission to show notifications.
    var notificationPermissionService: NotificationPermissionServiceProtocol { get }

    /// Whether the Live Activity may run, as chosen in the settings.
    var liveActivitySettingsService: LiveActivitySettingsServiceProtocol { get }

    /// Keeps the home screen widgets and the Live Activity in step with the home's status.
    var homeStatusBroadcaster: HomeStatusBroadcasting { get }

    /// The places threats are watched around, with Плюс deciding the custom ones.
    var watchedPlacesProvider: WatchedPlacesProviding { get }

    /// The oblasts of the user's places, for «Мої місця».
    var watchedRegionsProvider: WatchedRegionsProviding { get }

    /// Whether the user has AirRaid Плюс.
    var entitlementService: EntitlementServiceProtocol { get }

    /// What the voice feed reads and how.
    var voiceSettingsService: VoiceSettingsServiceProtocol { get }

    /// The device's Ukrainian voice.
    var speechService: SpeechServiceProtocol { get }

    /// Reads the feed aloud while the user listens.
    var feedVoiceAnnouncer: FeedVoiceAnnouncing { get }
}
