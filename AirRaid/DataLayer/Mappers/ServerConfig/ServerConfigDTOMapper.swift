//
//  ServerConfigDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import CryptoKit
import Foundation

/// Turns the published config into a trusted ``ServerConfig``.
///
/// The config lives outside the backend, so it is checked twice: the Ed25519 signature proves the backend
/// published it, and the host allow-list caps the damage of a leaked signing key — an alerts app pointed at
/// a foreign server could show fake alerts.
nonisolated enum ServerConfigDTOMapper {

    /// - Parameters:
    ///   - dto: The config as received.
    ///   - publicKey: The backend's config-signing key.
    ///   - allowedHostSuffixes: Host suffixes the address may use, e.g. `.trycloudflare.com`.
    /// - Throws: ``ServerConfigError`` when the signature, the address or its host is not acceptable.
    static func toDomain(
        _ dto: ServerConfigDTO,
        publicKey: Curve25519.Signing.PublicKey,
        allowedHostSuffixes: [String]
    ) throws -> ServerConfig {
        guard let signature = Data(base64URLEncoded: dto.sig),
              publicKey.isValidSignature(signature, for: Data("\(dto.apiServerURL)\n\(dto.issuedAt)".utf8)) else {
            throw ServerConfigError.invalidSignature
        }
        let url = try validatedURL(dto.apiServerURL, allowedHostSuffixes: allowedHostSuffixes)
        return ServerConfig(apiServerURL: url, issuedAt: dto.issuedAt)
    }

    /// Checks an address against the allow-list; also used for the cached address, which carries no signature.
    ///
    /// - Throws: ``ServerConfigError/disallowedURL(_:)`` unless it is `https` on an allowed host.
    static func validatedURL(
        _ string: String,
        allowedHostSuffixes: [String]
    ) throws -> URL {
        guard let components = URLComponents(string: string),
              components.scheme == Constants.scheme,
              let host = components.host?.lowercased(),
              allowedHostSuffixes.contains(where: { host.hasSuffix($0) }),
              let url = components.url else {
            throw ServerConfigError.disallowedURL(string)
        }
        return url
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let scheme = "https"
}
