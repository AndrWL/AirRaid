//
//  RealtimeConnectionState.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// The state of the live connection to the backend, as the UI needs it.
///
/// Deliberately coarser than the transport state: screens show "live", "connecting", or "offline",
/// not backoff details.
enum RealtimeConnectionState: Equatable {

    /// Not connected and not trying — before `start()`, after `stop()`, or after giving up.
    case disconnected

    /// Connecting for the first time or reconnecting after a drop.
    case connecting

    /// Live: updates arrive in real time.
    case connected

    /// The device is offline; the connection resumes automatically.
    case waitingForNetwork

    /// The server refuses this app version (`426`). Reconnecting stops; only an app update helps.
    case upgradeRequired
}
