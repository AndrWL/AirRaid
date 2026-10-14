//
//  AppEnvironment.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Backend endpoints and other per-environment values.
///
/// - Note: `nonisolated` because the target defaults to MainActor and DI factories read these off the main actor.
nonisolated enum AppEnvironment {

    /// The config Worker that publishes the current «Небо» API server address.
    ///
    /// The server runs behind a temporary Cloudflare tunnel whose address changes on every restart; the backend
    /// re-publishes it here, so builds keep working without a rebuild. See ``ServerConfigService``.
    static let serverConfigURLString = "https://steep-snowflake-bca4.andrewlebedev13.workers.dev/config.json"

    /// The backend's Ed25519 key (raw, base64url) that signs the published config. Public by design.
    static let serverConfigPublicKey = "sWA872k9QV-31i9IaloUB5fddEI4g6NK0PvsYm9R9x0"

    /// Hosts the published address may point to. Add the permanent domain here once there is one.
    static let allowedServerHostSuffixes = [".trycloudflare.com"]

    /// The developer key for `POST /v1/dev/token` (`DEV_KEY` on the server), from `AppSecrets.swift`.
    ///
    /// Simulator builds only — App Attest does not work there — so device builds, Release included, can never
    /// contain it. `nil` when empty: the simulator then falls back to a limited unattested token.
    static var devKey: String? {
        #if targetEnvironment(simulator)
        AppSecrets.devKey.isEmpty ? nil : AppSecrets.devKey
        #else
        nil
        #endif
    }

    /// The MapLibre style for the base map. OpenFreeMap: free, no API key.
    ///
    /// - Note: `AirRaidMapView` restyles labels by OpenMapTiles layer IDs (`place_*`), so another
    ///   OpenMapTiles-based style keeps working; a style with a different schema loses those tweaks.
    static let mapStyleURLString = "https://tiles.openfreemap.org/styles/dark"

    /// Where «Написати розробнику» in the settings sends its email.
    static let feedbackEmail = "andrewlebedev13@gmail.com"
}
