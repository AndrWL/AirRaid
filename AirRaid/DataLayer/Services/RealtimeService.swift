//
//  RealtimeService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Combine
import Foundation
import OSLog
import UIKit
import WebSocketClient

/// Default ``RealtimeServiceProtocol`` on top of ``WebSocketClientProtocol``.
///
/// The single consumer of the client's event stream: fans events out into Combine subjects for any number
/// of subscribers. Disconnects when the app goes to the background — iOS suspends sockets there anyway —
/// and reconnects when it returns, as long as the service is started.
final class RealtimeService {

    // MARK: - Variables

    private let client: WebSocketClientProtocol
    private let connectionStateSubject = CurrentValueSubject<RealtimeConnectionState, Never>(.disconnected)
    private let messageSubject = PassthroughSubject<Data, Never>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var isStarted = false
    private var isInBackground = false
    private var eventsTask: Task<Void, Never>?
    /// The last queued `connect`/`disconnect` call; each new call awaits it so they reach the client in order.
    private var lastCommand: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(
        client: WebSocketClientProtocol,
        notificationCenter: NotificationCenter = .default
    ) {
        self.client = client
        observeEvents()
        observeAppLifecycle(notificationCenter: notificationCenter)
    }

    deinit {
        eventsTask?.cancel()
    }
}

// MARK: - RealtimeServiceProtocol

extension RealtimeService: RealtimeServiceProtocol {

    var connectionState: RealtimeConnectionState {
        connectionStateSubject.value
    }

    var connectionStatePublisher: AnyPublisher<RealtimeConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }

    var messagePublisher: AnyPublisher<Data, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        if !isInBackground {
            enqueue { await $0.connect() }
        }
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        enqueue { await $0.disconnect() }
    }

    func send(_ payload: Data) async throws {
        try await client.send(.data(payload))
    }
}

// MARK: - Private methods

private extension RealtimeService {

    func observeEvents() {
        let events = client.events
        eventsTask = Task { [weak self] in
            for await event in events {
                self?.handle(event)
            }
        }
    }

    func observeAppLifecycle(notificationCenter: NotificationCenter) {
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleDidEnterBackground()
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleWillEnterForeground()
            }
            .store(in: &cancellables)
    }

    func handleDidEnterBackground() {
        isInBackground = true
        guard isStarted else { return }
        enqueue { await $0.disconnect() }
    }

    func handleWillEnterForeground() {
        isInBackground = false
        guard isStarted else { return }
        enqueue { await $0.connect() }
    }

    func enqueue(_ command: @escaping @Sendable (WebSocketClientProtocol) async -> Void) {
        let previous = lastCommand
        let client = client
        lastCommand = Task {
            await previous?.value
            await command(client)
        }
    }

    func handle(_ event: WebSocketEvent) {
        switch event {
        case .stateChanged(let state):
            let mappedState = RealtimeConnectionStateMapper.map(state)
            if mappedState != connectionStateSubject.value {
                connectionStateSubject.send(mappedState)
            }
        case .message(.data(let data)):
            messageSubject.send(data)
        case .message(.text(let text)):
            messageSubject.send(Data(text.utf8))
        case .failure(let error):
            logger.error("WebSocket failure: \(String(describing: error), privacy: .public)")
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Realtime"
}
