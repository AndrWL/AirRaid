//
//  StubWebSocketTaskFactory.swift
//  WebSocketClientTests
//

import Foundation
import WebSocketClient

/// Hands out pre-built ``StubWebSocketTask``s in order, then default ones, and records every request.
final class StubWebSocketTaskFactory: @unchecked Sendable {

    private struct State {
        var pendingTasks: [StubWebSocketTask]
        var createdTasks: [StubWebSocketTask] = []
        var requests: [URLRequest] = []
    }

    // Unchecked Sendable: all mutable state is behind `LockIsolated`.
    private let state: LockIsolated<State>

    init(
        tasks: [StubWebSocketTask] = []
    ) {
        self.state = LockIsolated(State(pendingTasks: tasks))
    }

    var createdTasks: [StubWebSocketTask] { state.value.createdTasks }
    var requests: [URLRequest] { state.value.requests }
}

// MARK: - WebSocketTaskFactoryProtocol

extension StubWebSocketTaskFactory: WebSocketTaskFactoryProtocol {

    func makeTask(with request: URLRequest) -> WebSocketTaskProtocol {
        state.withValue { state in
            let task = state.pendingTasks.isEmpty ? StubWebSocketTask() : state.pendingTasks.removeFirst()
            state.createdTasks.append(task)
            state.requests.append(request)
            return task
        }
    }
}
