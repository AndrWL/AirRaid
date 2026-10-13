//
//  NearestThreatCard.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The threat closest to the user: what it is, how far, and how soon it could arrive. A tap opens its details.
struct NearestThreatCard: View {

    // MARK: - Variables

    let summary: NearestThreatSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.small) {
                Image(summary.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(.ink)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(summary.title)
                        .font(.app(.subheadline, weight: .semibold))
                        .foregroundStyle(.ink)
                    Text(detailText)
                        .font(.app(.caption))
                        .foregroundStyle(.inkMuted)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .glassBackground(in: .rect(cornerRadius: Radius.large))
            // The whole card: a tap between the icon and the text would otherwise reach the map below.
            .contentShape(.rect(cornerRadius: Radius.large))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Найближча загроза: \(summary.title), \(detailText), оцінка")
    }
}

// MARK: - Private methods

private extension NearestThreatCard {

    /// «14 км від дому · ≈ 4 хв · ще 2».
    var detailText: String {
        var parts = [summary.distanceText]
        if let arrivalText = summary.arrivalText {
            parts.append(arrivalText)
        }
        if summary.otherCount > 0 {
            parts.append("ще \(summary.otherCount)")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Constants

private enum Constants {
    static let iconSize: CGFloat = 22
}
