//
//  NearThreatRow.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The nearest threat in the place's radius: its silhouette, name, distance and the forecast arrival.
struct NearThreatRow: View {

    /// Whether the threat is inside the place's radius (red), or the nearest one beyond it (muted).
    enum Tone {
        case inside
        case outside
    }

    /// How much room the row has.
    enum Style {
        /// Two short lines at the foot of the small widget.
        case compact
        /// A full row with the forecast arrival on the right: the Live Activity.
        case regular
    }

    // MARK: - Variables

    let threat: NearThreat
    let placeKind: StatusPlaceKind
    let now: Date
    let style: Style
    var tone: Tone = .inside

    var body: some View {
        HStack(spacing: style == .regular ? Spacing.medium : Spacing.xSmall) {
            icon
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(titleText)
                    .font(.app(style == .regular ? .headline : .caption, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                detail
            }
            if style == .regular {
                Spacer(minLength: Spacing.small)
                arrival
            }
        }
    }
}

// MARK: - Private methods

private extension NearThreatRow {

    var icon: some View {
        Image(threat.iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(tone == .inside ? Color.alertRed : Color.inkMuted)
            .frame(width: iconSize, height: iconSize)
            .accessibilityHidden(true)
    }

    var iconSize: CGFloat {
        style == .regular ? Constants.regularIconSize : Constants.compactIconSize
    }

    var titleText: String {
        threat.otherCount > 0 ? "\(threat.title) +\(threat.otherCount)" : threat.title
    }

    /// The compact row folds the arrival into the distance line; the regular one shows it apart.
    @ViewBuilder
    var detail: some View {
        if style == .compact, let arrivalAt = threat.arrivalAt, arrivalAt > now {
            Text("\(threat.distanceText) · \(WidgetTime.arrival(arrivalAt))")
                .font(.app(.caption2))
                .foregroundStyle(Color.inkMuted)
                .lineLimit(1)
        } else {
            Text(threat.distanceText)
                .font(.app(style == .regular ? .footnote : .caption2))
                .foregroundStyle(Color.inkMuted)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    var arrival: some View {
        if let arrivalAt = threat.arrivalAt, arrivalAt > now {
            VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
                Text(placeKind.arrivalLabel)
                    .font(.app(.caption2))
                    .foregroundStyle(Color.inkMuted)
                Text(WidgetTime.arrival(arrivalAt))
                    .font(.app(.title3, weight: .bold))
                    .foregroundStyle(tone == .inside ? Color.alertRed : Color.ink)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let compactIconSize: CGFloat = 16
    static let regularIconSize: CGFloat = 28
}
