//
//  ServerConfigRemoteDataSource.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Reads `config.json` from the config Worker.
nonisolated struct ServerConfigRemoteDataSource {

    // MARK: - Variables

    private let configURL: URL
    private let session: URLSession
    private let jsonDecoder: JSONDecoder

    init(
        configURL: URL,
        session: URLSession = .shared,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.configURL = configURL
        self.session = session
        self.jsonDecoder = jsonDecoder
    }
}

// MARK: - ServerConfigRemoteDataSourceProtocol

extension ServerConfigRemoteDataSource: ServerConfigRemoteDataSourceProtocol {

    func fetchConfig() async throws -> ServerConfigDTO {
        // Short timeout: a connection attempt waits for this, and a cached address is usually still good.
        let request = URLRequest(url: configURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: Constants.timeout)
        let (data, response) = try await session.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try jsonDecoder.decode(ServerConfigDTO.self, from: data)
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let timeout: TimeInterval = 5
}
