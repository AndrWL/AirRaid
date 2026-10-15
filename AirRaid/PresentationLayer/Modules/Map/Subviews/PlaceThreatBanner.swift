//
//  PlaceThreatBanner.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// A red banner over the map while a threat is inside the radius of one of the user's places: what it is, how far,
/// and how soon it could get there. A tap opens its details.
struct PlaceThreatBanner: View {

    // MARK: - Variables

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let summary: NearestThreatSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: summary.place.kind.systemImage)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(summary.place.kind.tint)
                    .frame(width: Constants.placeBadgeSize, height: Constants.placeBadgeSize)
                    .background(.white, in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(titleText)
                        .font(.app(.subheadline, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(detailText)
                        .font(.app(.caption, weight: .medium))
                        .foregroundStyle(.white.opacity(Constants.detailOpacity))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                Spacer(minLength: 0)
                Image(summary.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.threatGlyphSize, height: Constants.threatGlyphSize)
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, isActive: !reduceMotion)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Color.alertRed, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.large)
        .accessibilityLabel("\(titleText). \(detailText), оцінка")
        .accessibilityHint("Відкрити деталі загрози")
    }
}

// MARK: - Private methods

private extension PlaceThreatBanner {

    /// «Шахед біля дому», «Шахед поруч з вами», «Шахед біля «Робота»».
    var titleText: String {
        "\(summary.title) \(summary.place.nearText)"
    }

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
    static let placeBadgeSize: CGFloat = 28
    static let threatGlyphSize: CGFloat = 22
    static let detailOpacity: Double = 0.85
}
