//
//  RealtimeEndpoint.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Builds the WebSocket address of the «Небо» API: `wss://<server>/v1/ws[?since=<version>]`.
///
/// The server address and `since` change between attempts, so the address is rebuilt before every connection
/// attempt. Credentials go in the `Authorization` header, not the URL, which ends up in tunnel logs.
nonisolated enum RealtimeEndpoint {

    /// The application-level heartbeat. The server answers `{"type":"pong","version":N}`; per the API guide the
    /// client sends it every 30 s and reconnects if nothing arrives within 10 s.
    static let pingMessage = #"{"type":"ping"}"#

    static let pingInterval: Duration = .seconds(30)

    static let pongTimeout: Duration = .seconds(10)

    /// Close code for an expired or invalid token: refresh it and reconnect with `since`.
    static let tokenRejectedCloseCode = 4401

    /// Close code for a revoked installation: attest again; a refreshed token would be refused too.
    static let installationRevokedCloseCode = 4403

    /// Upgrade status for an app below the server's minimum version; reconnecting cannot help.
    static let upgradeRequiredStatusCode = 426

    /// - Parameters:
    ///   - serverURLString: The server's base address, `https://` or `wss://`; any path is replaced.
    ///   - since: The last applied version, or `nil` to get a full snapshot.
    /// - Throws: ``RealtimeEndpointError`` when the address is not usable.
    static func makeWebSocketURL(
        serverURLString: String,
        since: Int?
    ) throws -> URL {
        guard var components = URLComponents(string: serverURLString), components.host != nil else {
            throw RealtimeEndpointError.invalidServerURL(serverURLString)
        }

        // Plain HTTP stays unencrypted (a local server); everything else goes over TLS.
        switch components.scheme {
        case Constants.insecureScheme, Constants.insecureWebSocketScheme:
            components.scheme = Constants.insecureWebSocketScheme
        default:
            components.scheme = Constants.webSocketScheme
        }
        components.path = Constants.path
        components.queryItems = since.map { [URLQueryItem(name: Constants.sinceQueryItem, value: String($0))] }

        guard let url = components.url else { throw RealtimeEndpointError.invalidServerURL(serverURLString) }
        return url
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let path = "/v1/ws"
    static let webSocketScheme = "wss"
    static let insecureScheme = "http"
    static let insecureWebSocketScheme = "ws"
    static let sinceQueryItem = "since"
}
