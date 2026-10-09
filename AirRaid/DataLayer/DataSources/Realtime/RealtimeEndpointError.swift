//
//  RealtimeEndpointError.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import WebSocketClient

/// Why ``RealtimeEndpoint`` could not build the WebSocket address — a configuration problem, not a network one.
///
/// Non-retryable: reconnecting cannot fix it, so the client stops instead of retrying every 30 s.
nonisolated enum RealtimeEndpointError: WebSocketNonRetryableError, Equatable {

    /// The server address is not a URL.
    case invalidServerURL(String)
}
