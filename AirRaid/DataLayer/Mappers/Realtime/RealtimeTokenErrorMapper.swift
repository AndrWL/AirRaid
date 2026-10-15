//
//  RealtimeTokenErrorMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 15.10.2026.
//

import WebSocketClient

/// Turns a failed token request into the error the WebSocket client should see.
///
/// Once the token expires, an outdated app is refused at the auth endpoints (`upgrade_required`) before the socket
/// ever reaches the server's `426`. Without this the client would retry that forever behind «Підключаємося…»; as a
/// `426` it stops, and ``RealtimeService`` reports ``RealtimeConnectionState/upgradeRequired`` like for the socket.
nonisolated enum RealtimeTokenErrorMapper {

    /// - Returns: A `426` ``WebSocketClientError/handshakeFailed(statusCode:)`` for a refused app version,
    ///   the error itself for anything else.
    static func map(_ error: Error) -> Error {
        guard let error = error as? AuthAPIError,
              error.code == AuthAPIError.Code.upgradeRequired
                || error.statusCode == RealtimeEndpoint.upgradeRequiredStatusCode
        else { return error }
        return WebSocketClientError.handshakeFailed(statusCode: RealtimeEndpoint.upgradeRequiredStatusCode)
    }
}
