//
//  ServerAddressProviding.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Supplies the current API server address, which changes whenever the backend's tunnel restarts.
nonisolated protocol ServerAddressProviding: Sendable {

    /// The address to use for the next request or connection attempt.
    ///
    /// Refreshes the published config first when it has not been checked recently, so a connection that keeps
    /// failing picks up a moved server on a later attempt.
    ///
    /// - Throws: When no valid address was ever received.
    func fetchServerURL() async throws -> URL
}
