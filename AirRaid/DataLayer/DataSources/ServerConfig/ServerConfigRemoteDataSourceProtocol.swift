//
//  ServerConfigRemoteDataSourceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Fetches the published server config; exists so ``ServerConfigService`` can be tested without the network.
nonisolated protocol ServerConfigRemoteDataSourceProtocol: Sendable {

    func fetchConfig() async throws -> ServerConfigDTO
}
