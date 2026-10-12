//
//  RegionAlertRow.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// One official alert as a list row: where, what, since when and for how long.
struct RegionAlertRow: Identifiable, Hashable {

    // MARK: - Variables

    let id: String

    /// «Полтавський район».
    let name: String

    /// The alert kind when it is not a plain air raid, e.g. «Загроза артобстрілу».
    let kindText: String?

    /// `nil` for alerts other than air raids, which have no level.
    let level: RegionAlertLevel?

    /// «з 10:28»; with the date when the alert began on another day.
    let startedText: String

    /// «1 год 52 хв».
    let durationText: String

    init(
        alert: RegionAlert,
        now: Date
    ) {
        id = alert.id
        name = alert.name
        kindText = Self.makeKindText(for: alert.kind)
        level = alert.kind == .airRaid ? alert.level ?? .red : nil
        startedText = DisplayTime.since(alert.startedAt, now: now)
        durationText = DisplayTime.duration(max(now.timeIntervalSince(alert.startedAt), 0))
    }
}

// MARK: - Private methods

private extension RegionAlertRow {

    static func makeKindText(for kind: RegionAlertKind) -> String? {
        switch kind {
        case .airRaid: return nil
        case .artilleryShelling: return "Загроза артобстрілу"
        case .urbanFights: return "Загроза вуличних боїв"
        case .chemical: return "Хімічна загроза"
        case .nuclear: return "Радіаційна загроза"
        case .unknown: return "Інша загроза"
        }
    }
}
