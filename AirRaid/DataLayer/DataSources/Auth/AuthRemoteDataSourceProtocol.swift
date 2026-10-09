//
//  AuthRemoteDataSourceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// The backend's auth endpoints; exists so ``AuthService`` can be tested without the network.
///
/// Every method throws ``AuthAPIError`` for a non-2xx answer and `URLError` for transport failures.
nonisolated protocol AuthRemoteDataSourceProtocol: Sendable {

    /// `POST /v1/auth/challenge`.
    func fetchChallenge() async throws -> ChallengeDTO

    /// `POST /v1/auth/attest`: registers a new installation and returns its first token.
    func attest(_ request: AttestRequestDTO) async throws -> AccessTokenDTO

    /// `POST /v1/auth/token`: a new token for an attested installation.
    func fetchToken(_ request: TokenRequestDTO) async throws -> AccessTokenDTO

    /// `POST /v1/dev/token`: simulator builds only.
    func fetchDevToken(devKey: String) async throws -> AccessTokenDTO

    /// `POST /v1/token/unattested`: for devices that cannot attest.
    func fetchUnattestedToken() async throws -> AccessTokenDTO
}
