//
//  RealtimeServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Combine
import Foundation

/// The live connection to the backend.
///
/// Owns the connection lifecycle for the whole app: once started, it stays connected, reconnects on its own,
/// pauses in the background and resumes in the foreground.
///
/// - Note: Messages are raw payloads until the backend message protocol is defined; repositories decode them
///   into domain models.
protocol RealtimeServiceProtocol {

    /// The current connection state.
    var connectionState: RealtimeConnectionState { get }

    /// Emits the current state on subscription and every change after it.
    var connectionStatePublisher: AnyPublisher<RealtimeConnectionState, Never> { get }

    /// Emits every payload received from the server. Text frames are delivered as UTF-8 data.
    var messagePublisher: AnyPublisher<Data, Never> { get }

    /// Starts the connection and keeps it alive until ``stop()``.
    func start()

    /// Closes the connection and stops reconnecting.
    func stop()

    /// Sends a payload to the server.
    ///
    /// - Throws: An error if the connection is not live or the send fails.
    func send(_ payload: Data) async throws
}
