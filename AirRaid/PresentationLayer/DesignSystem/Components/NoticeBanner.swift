//
//  NoticeBanner.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// A glass capsule over the map saying the data is not live: connecting, offline, or an update is required.
///
/// Not for alerts and not for failed actions — only for the state of the data feed.
struct NoticeBanner: View {

    // MARK: - Variables

    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let isPulsing: Bool

    /// - Parameters:
    ///   - systemImage: The SF Symbol of the state.
    ///   - title: What is wrong, in a few words.
    ///   - subtitle: Since when the data is stale, or what it means.
    ///   - isPulsing: Pulses the glyph while something is in progress (connecting).
    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        isPulsing: Bool = false
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.isPulsing = isPulsing
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .font(.app(.subheadline, weight: .semibold))
                .foregroundStyle(.warning)
                .symbolEffect(.pulse, isActive: isPulsing)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.app(.caption))
                        .foregroundStyle(.inkMuted)
                }
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Constants.verticalPadding)
        .glassBackground(in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private enum Constants {
    static let verticalPadding: CGFloat = 10
}

#Preview {
    VStack(spacing: Spacing.large) {
        NoticeBanner(
            systemImage: "arrow.triangle.2.circlepath",
            title: "Підключаємося…",
            subtitle: "Дані станом на 21:40",
            isPulsing: true
        )
        NoticeBanner(systemImage: "wifi.slash", title: "Немає з'єднання", subtitle: "Дані станом на 21:40")
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}
