//
//  URLSessionWebSocketTaskAdapter.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Bridges `URLSessionWebSocketTask` to ``WebSocketTaskProtocol``.
struct URLSessionWebSocketTaskAdapter {

    // MARK: - Variables

    private let task: URLSessionWebSocketTask

    init(
        task: URLSessionWebSocketTask
    ) {
        self.task = task
    }
}

// MARK: - WebSocketTaskProtocol

extension URLSessionWebSocketTaskAdapter: WebSocketTaskProtocol {

    var httpStatusCode: Int? {
        (task.response as? HTTPURLResponse)?.statusCode
    }

    func resume() {
        task.resume()
    }

    func cancel() {
        task.cancel(with: .normalClosure, reason: nil)
    }

    func send(_ message: WebSocketMessage) async throws {
        switch message {
        case .text(let text):
            try await task.send(.string(text))
        case .data(let data):
            try await task.send(.data(data))
        }
    }

    func receive() async throws -> WebSocketMessage {
        switch try await task.receive() {
        case .string(let text):
            return .text(text)
        case .data(let data):
            return .data(data)
        @unknown default:
            throw WebSocketClientError.unsupportedMessage
        }
    }

    func sendPing() async throws {
        // `URLSession` calls the handler exactly once: on pong, or with an error when the task fails or is cancelled.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.sendPing { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
