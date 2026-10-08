//
//  RealtimeEndpoint.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Builds the WebSocket address of the «Небо» API: `wss://<server>/v1/ws?key=<key>[&since=<version>]`.
///
/// The API takes the key only as a query item on WebSocket upgrades, and `since` changes between attempts,
/// so the address is rebuilt before every connection attempt.
nonisolated enum RealtimeEndpoint {

    /// The application-level heartbeat. The server answers `{"type":"pong","version":N}`; per the API guide the
    /// client sends it every 30 s and reconnects if nothing arrives within 10 s.
    static let pingMessage = #"{"type":"ping"}"#

    static let pingInterval: Duration = .seconds(30)

    static let pongTimeout: Duration = .seconds(10)

    /// - Parameters:
    ///   - serverURLString: The server's base address, `https://` or `wss://`; any path is replaced.
    ///   - apiKey: The app key.
    ///   - since: The last applied version, or `nil` to get a full snapshot.
    /// - Throws: ``RealtimeEndpointError`` when the address or the key is missing.
    static func makeWebSocketURL(
        serverURLString: String,
        apiKey: String,
        since: Int?
    ) throws -> URL {
        guard !apiKey.isEmpty else { throw RealtimeEndpointError.missingAPIKey }
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
        // `URLQueryItem` leaves `+` as is, and servers read it as a space; keys are often base64.
        guard let encodedKey = apiKey.addingPercentEncoding(withAllowedCharacters: Constants.queryValueAllowed) else {
            throw RealtimeEndpointError.missingAPIKey
        }
        components.percentEncodedQueryItems = [URLQueryItem(name: Constants.keyQueryItem, value: encodedKey)]
            + (since.map { [URLQueryItem(name: Constants.sinceQueryItem, value: String($0))] } ?? [])

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
    static let keyQueryItem = "key"
    static let sinceQueryItem = "since"
    static let queryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&=;"))
}
