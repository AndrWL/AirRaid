//
//  AuthRemoteDataSource.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Calls the auth endpoints on the current API server.
nonisolated struct AuthRemoteDataSource {

    // MARK: - Variables

    private let serverAddressProvider: ServerAddressProviding
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    init(
        serverAddressProvider: ServerAddressProviding,
        session: URLSession = .shared,
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.serverAddressProvider = serverAddressProvider
        self.session = session
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }
}

// MARK: - AuthRemoteDataSourceProtocol

extension AuthRemoteDataSource: AuthRemoteDataSourceProtocol {

    func fetchChallenge() async throws -> ChallengeDTO {
        try await post(Constants.challengePath)
    }

    func attest(_ request: AttestRequestDTO) async throws -> AccessTokenDTO {
        try await post(Constants.attestPath, body: jsonEncoder.encode(request))
    }

    func fetchToken(_ request: TokenRequestDTO) async throws -> AccessTokenDTO {
        try await post(Constants.tokenPath, body: jsonEncoder.encode(request))
    }

    func fetchDevToken(devKey: String) async throws -> AccessTokenDTO {
        try await post(Constants.devTokenPath, headers: [Constants.devKeyHeader: devKey])
    }

    func fetchUnattestedToken() async throws -> AccessTokenDTO {
        try await post(Constants.unattestedTokenPath)
    }
}

// MARK: - Private methods

private extension AuthRemoteDataSource {

    func post<Response: Decodable>(
        _ path: String,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> Response {
        let serverURL = try await serverAddressProvider.fetchServerURL()
        var request = URLRequest(url: serverURL.appending(path: path), timeoutInterval: Constants.timeout)
        request.httpMethod = Constants.post
        for (field, value) in AppInfoHeaders.make().merging(headers, uniquingKeysWith: { _, new in new }) {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if let body {
            request.setValue(Constants.json, forHTTPHeaderField: Constants.contentType)
            request.httpBody = body
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorBody = try? jsonDecoder.decode(APIErrorDTO.self, from: data)
            throw AuthAPIError(
                statusCode: httpResponse.statusCode,
                code: errorBody?.error,
                message: errorBody?.message,
                retryAfter: httpResponse.value(forHTTPHeaderField: Constants.retryAfter).flatMap(TimeInterval.init)
            )
        }
        return try jsonDecoder.decode(Response.self, from: data)
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let challengePath = "v1/auth/challenge"
    static let attestPath = "v1/auth/attest"
    static let tokenPath = "v1/auth/token"
    static let devTokenPath = "v1/dev/token"
    static let unattestedTokenPath = "v1/token/unattested"
    static let devKeyHeader = "X-Dev-Key"
    static let retryAfter = "Retry-After"
    static let contentType = "Content-Type"
    static let json = "application/json"
    static let post = "POST"
    static let timeout: TimeInterval = 15
}
