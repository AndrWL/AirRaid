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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Найближча загроза: \(summary.title), \(detailText), оцінка")
    }
}

// MARK: - Private methods

private extension NearestThreatCard {

    /// «42 км від вас · ≈ 14 хв».
    var detailText: String {
        let distance = "\(summary.distanceText) від вас"
        return summary.arrivalText.map { "\(distance) · \($0)" } ?? distance
    }
}

// MARK: - Constants

private enum Constants {
    static let iconSize: CGFloat = 22
}
