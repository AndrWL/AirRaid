//
//  AppEnvironment.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Backend endpoints and other per-environment values.
///
/// - Warning: Placeholder values. Replace with the real backend before calling `RealtimeService.start()`,
///   and move to per-configuration `.xcconfig` files once there is more than one environment.
/// - Note: `nonisolated` because the target defaults to MainActor and DI factories read these off the main actor.
nonisolated enum AppEnvironment {

    /// The realtime WebSocket endpoint.
    static let webSocketURLString = "wss://example.com/ws"
}
