//
//  URLSessionWebSocketTaskAdapter.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation
import os

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

    var retryAfter: Duration? {
        // Only the delay-seconds form; servers that rate-limit WebSocket upgrades do not send HTTP dates.
        guard let value = (task.response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Retry-After"),
              let seconds = Int(value.trimmingCharacters(in: .whitespaces)),
              seconds >= 0 else {
            return nil
        }
        return .seconds(seconds)
    }

    var closeCode: Int? {
        task.closeCode == .invalid ? nil : task.closeCode.rawValue
    }

    var closeReason: String? {
        task.closeReason.flatMap { String(bytes: $0, encoding: .utf8) }
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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // `URLSession` may call the handler more than once when the connection aborts (e.g. POSIX 53
            // "Software caused connection abort") — the first call wins, later ones are dropped.
            let isResumed = OSAllocatedUnfairLock(initialState: false)
            task.sendPing { error in
                let isFirstCall = isResumed.withLock { isResumed in
                    defer { isResumed = true }
                    return !isResumed
                }
                guard isFirstCall else { return }
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
