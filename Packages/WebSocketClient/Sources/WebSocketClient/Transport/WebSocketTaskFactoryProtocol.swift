//
//  WebSocketTaskFactoryProtocol.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation

/// Creates a fresh ``WebSocketTaskProtocol`` for every connection attempt.
public protocol WebSocketTaskFactoryProtocol: Sendable {

    /// Makes a task for the given upgrade request. The task is not started.
    func makeTask(with request: URLRequest) -> WebSocketTaskProtocol
}
