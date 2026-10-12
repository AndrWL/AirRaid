//
//  RegionDetailsContent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// What the region sheet shows, formatted for one moment: the region's air raid state, its official alerts,
/// and the threats reported in it.
struct RegionDetailsContent {

    // MARK: - Variables

    /// «Полтавська область», «Київ».
    let title: String

    let status: RegionAlertStatus

    /// «Триває 1 год 12 хв» since the earliest air raid alert in the region; `nil` when there is none.
    let durationText: String?

    /// Every official alert in the region, earliest first.
    let alerts: [RegionAlertRow]

    /// Threats reported in the region.
    let threats: [ThreatRow]

    init(
        title: String,
        coverage: AirRaidCoverage,
        regionID: String,
        alerts: [RegionAlert],
        threats: [Threat],
        now: Date
    ) {
        self.title = title
        status = RegionAlertStatus(coverage: coverage, regionID: regionID)

        let airRaidStart = alerts.filter { $0.kind == .airRaid }.map(\.startedAt).min()
        durationText = airRaidStart.map { "Триває \(DisplayTime.duration(max(now.timeIntervalSince($0), 0)))" }

        self.alerts = alerts.map { RegionAlertRow(alert: $0, now: now) }
        self.threats = threats.map(ThreatRow.init)
    }
}

// MARK: - ThreatRow

extension RegionDetailsContent {

    /// One threat in the region.
    struct ThreatRow: Identifiable, Hashable {

        let id: String

        /// «Шахед ×3».
        let title: String

        /// «курсом на Кобеляки»; `nil` when only the region is known.
        let detail: String?

        /// The asset name of the threat's silhouette.
        let iconName: String

        init(threat: Threat) {
            id = threat.id
            let countText = threat.count.flatMap { $0 > 1 ? " ×\($0)" : nil } ?? ""
            title = threat.displayName + countText
            // The region is the sheet's title already, so a caption that only names it adds nothing.
            detail = threat.target != nil || threat.position != nil
                ? threat.mapCaption.map { "\($0.label) \($0.name)" }
                : nil
            iconName = ThreatIcon(threat).name
        }
    }
}
