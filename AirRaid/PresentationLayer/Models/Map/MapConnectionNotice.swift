//
//  MapConnectionNotice.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// Why the map may be out of date, worded for a banner over it.
///
/// Without it a dropped connection looks exactly like a quiet sky: the pins simply stop changing.
enum MapConnectionNotice: Equatable {

    /// Connecting or reconnecting; `since` is when the data was last live, `nil` before the first connection.
    case connecting(since: Date?)

    /// No network, or the connection gave up.
    case offline(since: Date?)

    /// The server refuses this app version, so the map will not update until the app is.
    case upgradeRequired

    init?(
        state: RealtimeConnectionState,
        liveUntil: Date?
    ) {
        switch state {
        case .connected:
            return nil
        case .connecting:
            self = .connecting(since: liveUntil)
        case .disconnected, .waitingForNetwork:
            self = .offline(since: liveUntil)
        case .upgradeRequired:
            self = .upgradeRequired
        }
    }

    var title: String {
        switch self {
        case .connecting: return "Підключаємося…"
        case .offline: return "Немає з'єднання"
        case .upgradeRequired: return UpgradeNotice.title
        }
    }

    /// Since when the data is current, or what to do; `nil` when there is nothing to add.
    var subtitle: String? {
        switch self {
        case .connecting(let since), .offline(let since):
            return since.map { "Дані станом на \($0.formatted(DisplayTime.clockStyle))" }
        case .upgradeRequired:
            return UpgradeNotice.subtitle
        }
    }

    /// Whether the app is still trying, so the banner glyph pulses.
    var isInProgress: Bool {
        if case .connecting = self {
            return true
        }
        return false
    }

    var systemImage: String {
        switch self {
        case .connecting: return "arrow.triangle.2.circlepath"
        case .offline: return "wifi.slash"
        case .upgradeRequired: return UpgradeNotice.systemImage
        }
    }
}
