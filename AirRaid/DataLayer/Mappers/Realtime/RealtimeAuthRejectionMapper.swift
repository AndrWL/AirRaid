//
//  RealtimeAuthRejectionMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import WebSocketClient

/// Recognises the WebSocket failures that mean the server refused the app's credentials.
nonisolated enum RealtimeAuthRejectionMapper {

    /// - Returns: The rejection to report to ``AuthTokenProviding``, or `nil` for failures unrelated to credentials.
    static func rejection(for failure: WebSocketClientError) -> AuthRejection? {
        switch failure {
        case .closedByServer(code: RealtimeEndpoint.tokenRejectedCloseCode, _):
            return .tokenRejected
        case .closedByServer(code: RealtimeEndpoint.installationRevokedCloseCode, _):
            return .installationRevoked
        // Sent only for an upgrade without credentials; a fresh token is the fix all the same.
        case .handshakeFailed(statusCode: Constants.unauthorizedStatusCode):
            return .tokenRejected
        default:
            return nil
        }
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let unauthorizedStatusCode = 401
}
