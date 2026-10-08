//
//  FrameCounter.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import os

/// Counts frames received on one connection, so the heartbeat can tell whether anything arrived after its ping.
///
/// Shared between the receive and heartbeat child tasks, hence the lock.
final class FrameCounter: Sendable {

    // MARK: - Variables

    private let storage = OSAllocatedUnfairLock(initialState: 0)

    var count: Int {
        storage.withLock { $0 }
    }

    // MARK: - Methods

    func increment() {
        storage.withLock { $0 += 1 }
    }
}
