//
//  NoticeBanner.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// A glass capsule over the map or the feed saying the data is not live: connecting, offline, or an update is required.
///
/// Not for alerts and not for failed actions — only for the state of the data feed.
struct NoticeBanner: View {

    /// A link at the trailing edge, for the one thing the user can do about the state: update the app.
    struct Action: Equatable {
        let title: String
        let url: URL
    }

    // MARK: - Variables

    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let isPulsing: Bool
    private let action: Action?

    /// - Parameters:
    ///   - systemImage: The SF Symbol of the state.
    ///   - title: What is wrong, in a few words.
    ///   - subtitle: Since when the data is stale, or what it means.
    ///   - isPulsing: Pulses the glyph while something is in progress (connecting).
    ///   - action: A link to the fix; `nil` when waiting is all there is to do.
    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        isPulsing: Bool = false,
        action: Action? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.isPulsing = isPulsing
        self.action = action
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
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
            // The link stays its own element, so VoiceOver can still activate it.
            .accessibilityElement(children: .combine)
            if let action {
                Link(action.title, destination: action.url)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(.onAccent)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(Color.accentColor, in: .capsule)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Constants.verticalPadding)
        .glassBackground(in: .capsule)
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
        if let url = URL(string: "https://apps.apple.com") {
            NoticeBanner(
                systemImage: "arrow.down.app",
                title: "Оновіть AirRaid, щоб бачити обстановку",
                subtitle: "Ця версія більше не отримує нових даних",
                action: NoticeBanner.Action(title: "Оновити", url: url)
            )
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}
