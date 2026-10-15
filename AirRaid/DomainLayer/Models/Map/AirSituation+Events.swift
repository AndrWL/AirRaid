//
//  AirSituation+Events.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

nonisolated extension AirSituation {

    /// The changes that turn `previous` into this situation, for when only the two states are known — a fresh
    /// snapshot. Gone threats close with ``ThreatCloseReason/unknown``: the snapshot does not say why.
    ///
    /// - Parameters:
    ///   - previous: The situation before.
    ///   - date: When the change was noticed — the time of closing and ending.
    /// - Returns: Closings first, then new and updated threats in the order they were first seen, then the same for
    ///   alerts.
    func events(
        since previous: AirSituation,
        at date: Date
    ) -> [AirSituationEvent] {
        let oldThreats = Dictionary(previous.threats.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let newThreats = Dictionary(threats.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let oldAlerts = Dictionary(previous.alerts.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let newAlerts = Dictionary(alerts.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })

        var events: [AirSituationEvent] = []
        for threat in previous.threats where newThreats[threat.id] == nil {
            events.append(.threatClosed(threat, reason: .unknown, at: date))
        }
        for threat in threats.sorted(by: { $0.firstSeenAt < $1.firstSeenAt }) where oldThreats[threat.id] != threat {
            events.append(.threatUpdated(threat, previous: oldThreats[threat.id]))
        }
        for alert in previous.alerts where newAlerts[alert.id] == nil {
            events.append(.alertEnded(alert, at: date))
        }
        for alert in alerts.sorted(by: { $0.startedAt < $1.startedAt }) where oldAlerts[alert.id] != alert {
            events.append(.alertStarted(alert, previous: oldAlerts[alert.id]))
        }
        return events
    }
}
