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

    /// The app key for the «Небо» API (`APP_KEYS` on the server), from `AppSecrets.swift`.
    ///
    /// - Warning: A key compiled into the app can be extracted. Move it to Keychain behind a settings screen
    ///   (or a short-lived token) before a public release.
    static let apiKey = AppSecrets.apiKey

    /// The MapLibre style for the base map. OpenFreeMap: free, no API key.
    ///
    /// - Note: `AirRaidMapView` restyles labels by OpenMapTiles layer IDs (`place_*`), so another
    ///   OpenMapTiles-based style keeps working; a style with a different schema loses those tweaks.
    static let mapStyleURLString = "https://tiles.openfreemap.org/styles/dark"
}
