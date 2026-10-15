//
//  RealtimeTokenErrorMapperTests.swift
//  AirRaidTests
//

import Foundation
import Testing
import WebSocketClient
@testable import AirRaid

/// Tests for ``RealtimeTokenErrorMapper/map(_:)``.
///
/// Covers that a token refused for an outdated app reaches the WebSocket client as the `426` that stops it, and that
/// every other failure passes through untouched, so the client keeps retrying it.
@Suite
struct RealtimeTokenErrorMapperTests {

    // MARK: - Refused version

    @Test
    func map_whenUpgradeRequiredCode_returnsUpgradeHandshakeFailure() {
        let error = AuthAPIError.stub(statusCode: 403, code: AuthAPIError.Code.upgradeRequired)

        let sut = RealtimeTokenErrorMapper.map(error)

        #expect(sut as? WebSocketClientError == .handshakeFailed(statusCode: RealtimeEndpoint.upgradeRequiredStatusCode))
    }

    @Test
    func map_whenUpgradeStatusWithoutCode_returnsUpgradeHandshakeFailure() {
        let error = AuthAPIError.stub(statusCode: RealtimeEndpoint.upgradeRequiredStatusCode, code: nil)

        let sut = RealtimeTokenErrorMapper.map(error)

        #expect(sut as? WebSocketClientError == .handshakeFailed(statusCode: RealtimeEndpoint.upgradeRequiredStatusCode))
    }

    // MARK: - Other failures

    @Test
    func map_whenOtherAuthError_returnsItUnchanged() {
        let error = AuthAPIError.stub(statusCode: 503, code: AuthAPIError.Code.attestUnavailable)

        let sut = RealtimeTokenErrorMapper.map(error)

        #expect(sut as? AuthAPIError == error)
    }

    @Test
    func map_whenNetworkError_returnsItUnchanged() {
        let error = URLError(.notConnectedToInternet)

        let sut = RealtimeTokenErrorMapper.map(error)

        #expect((sut as? URLError)?.code == .notConnectedToInternet)
    }
}

// MARK: - AuthAPIError

private extension AuthAPIError {

    static func stub(
        statusCode: Int,
        code: String?
    ) -> AuthAPIError {
        AuthAPIError(statusCode: statusCode, code: code, message: nil, retryAfter: nil)
    }
}
