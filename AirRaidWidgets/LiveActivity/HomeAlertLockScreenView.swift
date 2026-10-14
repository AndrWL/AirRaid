//
//  HomeAlertLockScreenView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI
import WidgetKit

/// The Live Activity on the lock screen and in a notification banner.
struct HomeAlertLockScreenView: View {

    // MARK: - Variables

    let placeKind: StatusPlaceKind
    let placeName: String
    let state: HomeAlertActivityState
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header
            content
            if isStale {
                Text("Дані могли застаріти: відкрийте AirRaid")
                    .font(.app(.caption, weight: .semibold))
                    .foregroundStyle(Color.warningInk)
            }
        }
        .padding(Spacing.large)
    }
}

// MARK: - Private methods

private extension HomeAlertLockScreenView {

    var header: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            StatusDot(state.dotTone)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(state.headline)
                    .font(.app(.headline, weight: .bold))
                    .foregroundStyle(Color.ink)
                Text("\(placeName) · радіус \(Int(state.radiusKm)) км")
                    .font(.app(.footnote))
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.small)
            if let alert = state.alert {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("триває")
                        .font(.app(.caption2))
                        .foregroundStyle(Color.inkMuted)
                    Text(WidgetTime.since(alert.startedAt, now: .now))
                        .font(.app(.title2, weight: .bold))
                        .foregroundStyle(alert.level.textColor)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    var content: some View {
        if state.isAllClear {
            Text("Тривогу \(placeKind.nearText) скасовано")
                .font(.app(.subheadline))
                .foregroundStyle(Color.inkMuted)
        } else {
            ThreatSummaryView(state: state, placeKind: placeKind)
        }
    }
}

// MARK: - Previews

#Preview("Lock screen", as: .content, using: HomeAlertActivityAttributes(placeKind: .home, placeName: "Ірпінь")) {
    HomeAlertLiveActivity()
} contentStates: {
    HomeAlertActivityState.previewThreat
    HomeAlertActivityState.previewOutside
    HomeAlertActivityState.previewThreatOnly
    HomeAlertActivityState.previewClear
    HomeAlertActivityState.previewEnded
}

#Preview("Island expanded", as: .dynamicIsland(.expanded), using: HomeAlertActivityAttributes(placeKind: .home, placeName: "Ірпінь")) {
    HomeAlertLiveActivity()
} contentStates: {
    HomeAlertActivityState.previewThreat
    HomeAlertActivityState.previewOutside
    HomeAlertActivityState.previewClear
}

#Preview("Island compact", as: .dynamicIsland(.compact), using: HomeAlertActivityAttributes(placeKind: .home, placeName: "Ірпінь")) {
    HomeAlertLiveActivity()
} contentStates: {
    HomeAlertActivityState.previewThreat
    HomeAlertActivityState.previewOutside
    HomeAlertActivityState.previewClear
}
