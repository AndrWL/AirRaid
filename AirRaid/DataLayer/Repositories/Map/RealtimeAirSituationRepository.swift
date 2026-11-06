//
//  RealtimeAirSituationRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import Foundation
import OSLog

/// The live air situation from the Nebo API, kept in sync over ``RealtimeServiceProtocol``.
///
/// Strategy: network-only, in memory. Holds every active event by `id`, every official alert by `uid`, plus the last
/// applied `version`:
/// - `snapshot` replaces the whole state, events and alerts;
/// - `changes`: `upsert` replaces an event entirely (an `id` closed earlier may come back), `close` removes it
///   (an unknown `id` is ignored; for `merged` the survivor's `upsert` is in the same message); `alert_on` replaces
///   an alert by `uid`, `alert_off` removes it;
/// - a `changes` version below the stored one means the server restarted — the cursor is reset and a `subscribe`
///   asks for a fresh snapshot;
/// - unknown message types are ignored, but their version is kept.
///
/// The version goes to ``RealtimeVersionStore``, so a reconnect resumes with `since` and receives only what was
/// missed. While disconnected, the last known situation stays published.
final class RealtimeAirSituationRepository {

    // MARK: - Variables

    private let realtimeService: RealtimeServiceProtocol
    private let versionStore: RealtimeVersionStore
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let situationSubject = CurrentValueSubject<AirSituation, Never>(.empty)
    private let eventsSubject = PassthroughSubject<[AirSituationEvent], Never>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var threats: [String: Threat] = [:]
    private var alerts: [String: RegionAlert] = [:]
    /// The changes applied since the last publish, sent together with the situation they led to.
    private var pendingEvents: [AirSituationEvent] = []
    private var cancellables: Set<AnyCancellable> = []

    init(
        realtimeService: RealtimeServiceProtocol,
        versionStore: RealtimeVersionStore,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.realtimeService = realtimeService
        self.versionStore = versionStore
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        observeMessages()
    }
}

// MARK: - AirSituationRepositoryProtocol

extension RealtimeAirSituationRepository: AirSituationRepositoryProtocol {

    var situationPublisher: AnyPublisher<AirSituation, Never> {
        situationSubject.eraseToAnyPublisher()
    }

    var eventsPublisher: AnyPublisher<[AirSituationEvent], Never> {
        eventsSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private methods

private extension RealtimeAirSituationRepository {

    func observeMessages() {
        realtimeService.messagePublisher
            .sink { [weak self] payload in
                self?.handle(payload)
            }
            .store(in: &cancellables)
    }

    func handle(_ payload: Data) {
        let message: RealtimeMessageDTO
        do {
            message = try jsonDecoder.decode(RealtimeMessageDTO.self, from: payload)
        } catch {
            logger.error("Failed to decode a message: \(String(describing: error), privacy: .public)")
            return
        }

        switch message.type {
        case MessageType.snapshot:
            applySnapshot(message)
        case MessageType.changes:
            applyChanges(message)
        case MessageType.pong:
            logger.debug("pong v\(message.version ?? -1)")
        default:
            logger.info("Ignored '\(message.type, privacy: .public)' v\(message.version ?? -1)")
            if let version = message.version {
                versionStore.version = version
            }
        }
    }

    func applySnapshot(_ message: RealtimeMessageDTO) {
        let newThreats = Dictionary(
            (message.events ?? []).map { ($0.id, ThreatEventDTOMapper.map($0)) },
            uniquingKeysWith: { _, latest in latest }
        )
        let newAlerts = Dictionary(
            (message.alerts ?? []).map { ($0.uid, RegionAlertDTOMapper.map($0)) },
            uniquingKeysWith: { _, latest in latest }
        )
        let previous = AirSituation(alerts: Array(alerts.values), threats: Array(threats.values))
        let next = AirSituation(alerts: Array(newAlerts.values), threats: Array(newThreats.values))
        pendingEvents.append(contentsOf: next.events(since: previous, at: .now))
        threats = newThreats
        alerts = newAlerts
        logger.info("snapshot v\(message.version ?? -1): \(self.threats.count) events, \(self.alerts.count) alerts")
        for threat in threats.values {
            logger.debug("  • \(Self.describe(threat), privacy: .public)")
        }
        versionStore.version = message.version
        publish()
    }

    func applyChanges(_ message: RealtimeMessageDTO) {
        if let version = message.version, let storedVersion = versionStore.version, version < storedVersion {
            logger.notice("changes v\(version) < stored v\(storedVersion): server restarted, resubscribing")
            resubscribe()
            return
        }

        let changes = message.changes ?? []
        logger.info("changes v\(message.version ?? -1): \(changes.count) change(s), \(self.threats.count) events before")
        changes.forEach(apply)
        if let version = message.version {
            versionStore.version = version
        }
        publish()
    }

    // One case per change type, each recording its feed event next to the state it changes.
    // swiftlint:disable:next cyclomatic_complexity
    func apply(_ change: ThreatChangeDTO) {
        switch change.type {
        case ChangeType.upsert:
            guard let event = change.event else { return }
            let threat = ThreatEventDTOMapper.map(event)
            logger.debug("  + \(Self.describe(threat), privacy: .public)")
            if threats[event.id] != threat {
                pendingEvents.append(.threatUpdated(threat, previous: threats[event.id]))
            }
            threats[event.id] = threat
        case ChangeType.close:
            guard let id = change.id else { return }
            let merged = change.mergedInto.map { " → \($0)" } ?? ""
            logger.debug("  − \(id, privacy: .public) (\(change.reason ?? "no reason", privacy: .public)\(merged, privacy: .public))")
            if let threat = threats[id] {
                pendingEvents.append(.threatClosed(threat, reason: Self.closeReason(change), at: .now))
            }
            threats[id] = nil
        case ChangeType.alertOn:
            guard let dto = change.alert else { return }
            let description = "\(dto.uid) \(dto.kind) \(dto.name) (\(dto.code))"
            logger.debug("  ⚠︎ on \(description, privacy: .public)")
            let alert = RegionAlertDTOMapper.map(dto)
            if alerts[dto.uid] != alert {
                pendingEvents.append(.alertStarted(alert, previous: alerts[dto.uid]))
            }
            alerts[dto.uid] = alert
        case ChangeType.alertOff:
            guard let uid = change.uid else { return }
            logger.debug("  ⚠︎ off \(uid, privacy: .public) (\(change.code ?? "?", privacy: .public))")
            if let alert = alerts[uid] {
                pendingEvents.append(.alertEnded(alert, at: .now))
            }
            alerts[uid] = nil
        default:
            logger.debug("  ? ignored change '\(change.type, privacy: .public)'")
        }
    }

    /// Recovers from a server restart: drop the stale cursor and ask for the full state in the same socket.
    ///
    /// If the send fails the connection is down anyway; the reconnect goes without `since` and gets a snapshot.
    func resubscribe() {
        versionStore.version = nil
        let command: String
        do {
            let data = try jsonEncoder.encode(RealtimeCommandDTO.subscribe())
            guard let text = String(bytes: data, encoding: .utf8) else {
                assertionFailure("[RealtimeAirSituationRepository] Encoded subscribe is not UTF-8")
                return
            }
            command = text
        } catch {
            assertionFailure("[RealtimeAirSituationRepository] Failed to encode subscribe: \(error)")
            return
        }
        Task { [realtimeService, logger] in
            do {
                try await realtimeService.send(command)
            } catch {
                logger.error("Failed to resubscribe: \(String(describing: error), privacy: .public)")
            }
        }
    }

    static func closeReason(_ change: ThreatChangeDTO) -> ThreatCloseReason {
        switch change.reason {
        case CloseReason.ended: .ended
        case CloseReason.cancelled: .cancelled
        case CloseReason.merged: .merged(survivorID: change.mergedInto)
        default: .unknown
        }
    }

    /// One line per event for the console: id, type, place, trust, and the backend's caption.
    static func describe(_ threat: Threat) -> String {
        let kind = threat.type.map { "\($0)" } ?? "\(threat.kind)"
        let place = threat.position?.name ?? threat.target.map { "→ \($0.name)" } ?? threat.area.name
        let caption = threat.summary.map { " — \($0)" } ?? ""
        return "\(threat.id) \(kind) @ \(place) [\(threat.level), \(threat.sourceCount) src]\(caption)"
    }

    func publish() {
        let sortedThreats = threats.values.sorted { lhs, rhs in
            (lhs.firstSeenAt, lhs.id) < (rhs.firstSeenAt, rhs.id)
        }
        let sortedAlerts = alerts.values.sorted { lhs, rhs in
            (lhs.regionID, lhs.id) < (rhs.regionID, rhs.id)
        }
        situationSubject.send(AirSituation(alerts: sortedAlerts, threats: sortedThreats))
        guard !pendingEvents.isEmpty else { return }
        let events = pendingEvents
        pendingEvents = []
        eventsSubject.send(events)
    }
}

// MARK: - Constants

private enum MessageType {
    static let snapshot = "snapshot"
    static let changes = "changes"
    static let pong = "pong"
}

private enum ChangeType {
    static let upsert = "upsert"
    static let close = "close"
    static let alertOn = "alert_on"
    static let alertOff = "alert_off"
}

private enum CloseReason {
    static let ended = "ended"
    static let cancelled = "cancelled"
    static let merged = "merged"
}

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "AirSituation"
}
