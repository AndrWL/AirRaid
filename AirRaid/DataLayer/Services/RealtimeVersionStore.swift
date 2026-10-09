//
//  RealtimeVersionStore.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import os

/// The last applied server `version` — the cursor for resuming the event stream after a drop.
///
/// Written by ``RealtimeAirSituationRepository`` on the main actor and read by the WebSocket client's URL provider
/// before every connection attempt, off the main actor — hence the lock. In memory only: after a relaunch the app
/// starts from a full snapshot.
nonisolated final class RealtimeVersionStore: Sendable {

    // MARK: - Variables

    private let storage = OSAllocatedUnfairLock<Int?>(initialState: nil)

    /// `nil` until the first snapshot, and after a server restart is detected.
    var version: Int? {
        get { storage.withLock { $0 } }
        set { storage.withLock { $0 = newValue } }
    }
}
