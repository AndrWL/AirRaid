//
//  URLSessionWebSocketTaskFactory.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Default ``WebSocketTaskFactoryProtocol`` backed by `URLSession`.
public struct URLSessionWebSocketTaskFactory {

    // MARK: - Variables

    private let session: URLSession

    /// - Parameter session: The session that owns the tasks. Pass a custom one for SSL pinning or proxies.
    public init(
        session: URLSession = .shared
    ) {
        self.session = session
    }
}

// MARK: - WebSocketTaskFactoryProtocol

extension URLSessionWebSocketTaskFactory: WebSocketTaskFactoryProtocol {

    public func makeTask(with request: URLRequest) -> WebSocketTaskProtocol {
        URLSessionWebSocketTaskAdapter(task: session.webSocketTask(with: request))
    }
}
