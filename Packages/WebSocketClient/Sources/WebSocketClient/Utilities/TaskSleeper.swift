//
//  TaskSleeper.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// Default ``Sleeping`` implementation on top of `Task.sleep`.
public struct TaskSleeper {

    public init() { }
}

// MARK: - Sleeping

extension TaskSleeper: Sleeping {

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
