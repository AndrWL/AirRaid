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

    /// The «Небо» API server, `https://<server>`. The WebSocket address is derived from it.
    ///
    /// - Warning: Comes from the git-ignored `AppSecrets.swift` (template: `AppSecrets.swift.example` in the repo
    ///   root). The server currently runs behind a temporary Cloudflare tunnel whose address changes on restart.
    static let apiServerURLString = AppSecrets.apiServerURLString

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
