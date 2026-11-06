//
//  HomeAlertIslandViews.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The pieces of the Dynamic Island. Its background is always black, so the colours are the dark variants.
enum HomeAlertIslandViews {

    /// The compact and minimal leading glyph: the silhouette of the threat in the radius (red) or of the closest one
    /// beyond it (white), else the alert's dot.
    @ViewBuilder
    static func glyph(_ state: HomeAlertActivityState) -> some View {
        if let threat = state.nearestThreat ?? state.closestThreat {
            Image(threat.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(state.nearestThreat == nil ? Color.ink : Color.alertRed)
                .frame(width: Constants.glyphSize, height: Constants.glyphSize)
        } else {
            Circle()
                .fill(state.color)
                .frame(width: Constants.dotSize, height: Constants.dotSize)
        }
    }

    /// The compact trailing text: the threat's short name with its distance, e.g. "FPV 45 km", red inside the radius, white
    /// beyond it; with no threat, the mood in one word.
    ///
    /// No times: «10:42» right of the status bar clock reads as the time of day, not as an arrival or an alert's start.
    @ViewBuilder
    static func compactText(_ state: HomeAlertActivityState) -> some View {
        Group {
            if let threat = state.nearestThreat {
                Text("\(threat.shortTitle) \(threat.shortDistanceText)")
                    .foregroundStyle(Color.alertRed)
            } else if let threat = state.closestThreat {
                Text("\(threat.shortTitle) \(threat.shortDistanceText)")
                    .foregroundStyle(Color.ink)
            } else {
                Text(state.shortHeadline)
                    .foregroundStyle(state.textColor)
            }
        }
        .font(.app(.footnote, weight: .semibold))
        .lineLimit(1)
        .minimumScaleFactor(Constants.compactMinimumScale)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: Constants.compactTextWidth, alignment: .trailing)
    }

    static func title(_ state: HomeAlertActivityState) -> some View {
        HStack(spacing: Spacing.xSmall) {
            StatusDot(state.dotTone)
            Text(state.shortHeadline)
                .font(.app(.headline, weight: .bold))
        }
        .padding(.leading, Spacing.xSmall)
    }

    @ViewBuilder
    static func duration(_ state: HomeAlertActivityState) -> some View {
        if let alert = state.alert {
            VStack(alignment: .trailing, spacing: 0) {
                Text("триває")
                    .font(.app(.caption2))
                    .foregroundStyle(Color.inkMuted)
                Text(WidgetTime.since(alert.startedAt, now: .now))
                    .font(.app(.headline, weight: .bold))
                    .foregroundStyle(alert.level.textColor)
                    .lineLimit(1)
            }
            .padding(.trailing, Spacing.xSmall)
        }
    }

    @ViewBuilder
    static func details(
        attributes: HomeAlertActivityAttributes,
        state: HomeAlertActivityState
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("\(attributes.placeName) · радіус \(Int(state.radiusKm)) км")
                .font(.app(.caption))
                .foregroundStyle(Color.inkMuted)
            if !state.isAllClear {
                ThreatSummaryView(state: state, placeKind: attributes.placeKind)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xSmall)
    }
}

// MARK: - Constants

private enum Constants {
    static let glyphSize: CGFloat = 20
    static let dotSize: CGFloat = 12
    /// A short name with a distance or an arrival time in the compact footnote.
    static let compactTextWidth: CGFloat = 96
    static let compactMinimumScale: CGFloat = 0.75
}
