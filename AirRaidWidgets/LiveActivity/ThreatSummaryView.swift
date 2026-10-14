//
//  ThreatSummaryView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The threat part of the Live Activity: the threat in the radius, else the closest one beyond it under a «поза
/// радіусом» note, else a line saying the sky around is clear.
struct ThreatSummaryView: View {

    // MARK: - Variables

    let state: HomeAlertActivityState
    let placeKind: StatusPlaceKind

    var body: some View {
        if let threat = state.nearestThreat {
            NearThreatRow(threat: threat, placeKind: placeKind, now: .now, style: .regular)
        } else if let threat = state.closestThreat {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Найближча загроза · поза радіусом \(Int(state.radiusKm)) км")
                    .font(.app(.caption))
                    .foregroundStyle(Color.inkMuted)
                NearThreatRow(threat: threat, placeKind: placeKind, now: .now, style: .regular, tone: .outside)
            }
        } else {
            Text("Поблизу загроз не видно")
                .font(.app(.subheadline))
                .foregroundStyle(Color.inkMuted)
        }
    }
}
