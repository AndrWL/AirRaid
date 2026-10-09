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
///
/// An app version the server refuses (`426`) stops the client; the service then reports
/// ``RealtimeConnectionState/upgradeRequired`` instead of a plain `disconnected` until the next ``start()``.
final class RealtimeService {

    // MARK: - Variables

    private let client: WebSocketClientProtocol
    private let connectionStateSubject = CurrentValueSubject<RealtimeConnectionState, Never>(.disconnected)
    private let messageSubject = PassthroughSubject<Data, Never>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var isStarted = false
    private var isInBackground = false
    private var isRejected = false
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
        // A preview's view model calls `start()` on appear; a canvas refresh must not open a real connection
        // (and count toward the server's 12-connections-per-minute limit).
        guard !isStarted, !Self.isRunningForPreviews else { return }
        isStarted = true
        isRejected = false
        if !isInBackground {
            enqueue { await $0.connect() }
        }
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        isRejected = false
        enqueue { await $0.disconnect() }
    }

    func send(_ text: String) async throws {
        logger.debug("⬆︎ \(text, privacy: .public)")
        try await client.send(.text(text))
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

    static var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment[Constants.previewsEnvironmentKey] == "1"
    }

    /// The payload as text, cut to ``Constants/maxLoggedPayloadLength`` — a snapshot can be tens of kilobytes.
    static func preview(of payload: Data) -> String {
        let text = String(bytes: payload, encoding: .utf8) ?? "<\(payload.count) B binary>"
        guard text.count > Constants.maxLoggedPayloadLength else { return "\(payload.count) B \(text)" }
        return "\(payload.count) B \(text.prefix(Constants.maxLoggedPayloadLength))…"
    }

    func handle(_ event: WebSocketEvent) {
        switch event {
        case .stateChanged(let state):
            logger.info("State: \(String(describing: state), privacy: .public)")
            // A new attempt (e.g. on returning to the foreground) gets a fresh verdict.
            if state == .connecting {
                isRejected = false
            }
            let mappedState = isRejected && state == .disconnected
                ? .upgradeRequired
                : RealtimeConnectionStateMapper.map(state)
            if mappedState != connectionStateSubject.value {
                connectionStateSubject.send(mappedState)
            }
        case .message(.data(let data)):
            logger.debug("⬇︎ \(Self.preview(of: data), privacy: .public)")
            messageSubject.send(data)
        case .message(.text(let text)):
            let data = Data(text.utf8)
            logger.debug("⬇︎ \(Self.preview(of: data), privacy: .public)")
            messageSubject.send(data)
        case .failure(let error):
            if case .handshakeFailed(let statusCode) = error, Constants.rejectedVersionStatusCodes.contains(statusCode) {
                isRejected = true
            }
            logger.error("WebSocket failure: \(String(describing: error), privacy: .public)")
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Realtime"
    /// Must match the client's `nonRetryableStatusCodes`, so `upgradeRequired` is reported only when the client stopped.
    static let rejectedVersionStatusCodes: Set<Int> = [RealtimeEndpoint.upgradeRequiredStatusCode]
    static let maxLoggedPayloadLength = 1_000
    static let previewsEnvironmentKey = "XCODE_RUNNING_FOR_PREVIEWS"
}
