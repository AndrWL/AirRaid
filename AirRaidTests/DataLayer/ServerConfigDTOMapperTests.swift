//
//  ServerConfigDTOMapperTests.swift
//  AirRaidTests
//

import CryptoKit
import Foundation
import Testing
@testable import AirRaid

/// Tests for ``ServerConfigDTOMapper``: the checks that keep the app off a foreign server.
///
/// Covers the Ed25519 signature over the address and the issue time (another key, a changed address or time, a
/// malformed signature) and the allow-list: `https` only, on a `.trycloudflare.com` host, which tricks with look-alike
/// hosts, user info, paths and fragments do not pass.
@Suite
struct ServerConfigDTOMapperTests {

    // MARK: - toDomain

    @Test
    func toDomain_whenSignedByBackendKey_returnsConfig() throws {
        let key = Curve25519.Signing.PrivateKey()
        let dto = try ServerConfigDTO.signed(url: Constants.url, issuedAt: 1_000, key: key)

        let config = try ServerConfigDTOMapper.toDomain(dto, publicKey: key.publicKey, allowedHostSuffixes: Constants.suffixes)

        #expect(config == ServerConfig(apiServerURL: try #require(URL(string: Constants.url)), issuedAt: 1_000))
    }

    @Test
    func toDomain_whenSignedByAnotherKey_throwsInvalidSignature() throws {
        let dto = try ServerConfigDTO.signed(url: Constants.url, issuedAt: 1_000, key: Curve25519.Signing.PrivateKey())

        #expect(throws: ServerConfigError.invalidSignature) {
            try ServerConfigDTOMapper.toDomain(
                dto,
                publicKey: Curve25519.Signing.PrivateKey().publicKey,
                allowedHostSuffixes: Constants.suffixes
            )
        }
    }

    @Test
    func toDomain_whenAddressSwappedUnderSignature_throwsInvalidSignature() throws {
        let key = Curve25519.Signing.PrivateKey()
        let signed = try ServerConfigDTO.signed(url: Constants.url, issuedAt: 1_000, key: key)
        let dto = ServerConfigDTO(apiServerURL: "https://other.trycloudflare.com", issuedAt: 1_000, sig: signed.sig)

        #expect(throws: ServerConfigError.invalidSignature) {
            try ServerConfigDTOMapper.toDomain(dto, publicKey: key.publicKey, allowedHostSuffixes: Constants.suffixes)
        }
    }

    @Test
    func toDomain_whenIssueTimeChangedUnderSignature_throwsInvalidSignature() throws {
        let key = Curve25519.Signing.PrivateKey()
        let signed = try ServerConfigDTO.signed(url: Constants.url, issuedAt: 1_000, key: key)
        let dto = ServerConfigDTO(apiServerURL: Constants.url, issuedAt: 2_000, sig: signed.sig)

        #expect(throws: ServerConfigError.invalidSignature) {
            try ServerConfigDTOMapper.toDomain(dto, publicKey: key.publicKey, allowedHostSuffixes: Constants.suffixes)
        }
    }

    @Test(arguments: ["", "not base64 !", "AAAA"])
    func toDomain_whenSignatureMalformed_throwsInvalidSignature(sig: String) {
        let dto = ServerConfigDTO(apiServerURL: Constants.url, issuedAt: 1_000, sig: sig)

        #expect(throws: ServerConfigError.invalidSignature) {
            try ServerConfigDTOMapper.toDomain(
                dto,
                publicKey: Curve25519.Signing.PrivateKey().publicKey,
                allowedHostSuffixes: Constants.suffixes
            )
        }
    }

    @Test
    func toDomain_whenSignedButHostNotAllowed_throwsDisallowedURL() throws {
        let key = Curve25519.Signing.PrivateKey()
        let dto = try ServerConfigDTO.signed(url: "https://evil.example.com", issuedAt: 1_000, key: key)

        #expect(throws: ServerConfigError.disallowedURL("https://evil.example.com")) {
            try ServerConfigDTOMapper.toDomain(dto, publicKey: key.publicKey, allowedHostSuffixes: Constants.suffixes)
        }
    }

    // MARK: - validatedURL

    @Test(arguments: [
        "https://quiet-river-1234.trycloudflare.com",
        "https://QUIET-RIVER.TRYCLOUDFLARE.COM",
        "https://a.b.trycloudflare.com:443/v1"
    ])
    func validatedURL_whenHttpsOnAllowedHost_returnsURL(string: String) throws {
        let url = try ServerConfigDTOMapper.validatedURL(string, allowedHostSuffixes: Constants.suffixes)

        #expect(url.absoluteString == string)
    }

    @Test(arguments: [
        "http://quiet-river.trycloudflare.com",
        "wss://quiet-river.trycloudflare.com",
        "https://trycloudflare.com",
        "https://eviltrycloudflare.com",
        "https://quiet-river.trycloudflare.com.evil.com",
        "https://quiet-river.trycloudflare.com@evil.com",
        "https://evil.com/.trycloudflare.com",
        "https://evil.com#.trycloudflare.com",
        "https://evil.com?.trycloudflare.com",
        "quiet-river.trycloudflare.com",
        ""
    ])
    func validatedURL_whenNotHttpsOnAllowedHost_throwsDisallowedURL(string: String) {
        #expect(throws: ServerConfigError.disallowedURL(string)) {
            try ServerConfigDTOMapper.validatedURL(string, allowedHostSuffixes: Constants.suffixes)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let url = "https://quiet-river-1234.trycloudflare.com"
    static let suffixes = [".trycloudflare.com"]
}
