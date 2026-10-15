//
//  FeedHomeCard.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The home's status above the feed, the same as the widget shows: the alert and the nearest threat.
struct FeedHomeCard: View {

    // MARK: - Variables

    private let status: HomeStatus

    init(status: HomeStatus) {
        self.status = status
    }

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: status.placeKind == .home ? "house.fill" : "location.fill")
                .font(.app(.title3, weight: .semibold))
                .foregroundStyle(status.alert == nil ? Color.allClearInk : Color.alertRedInk)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(status.placeName)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(.ink)
                    .lineLimit(1)
                Text(alertText)
                    .font(.app(.footnote))
                    .foregroundStyle(.inkMuted)
                if let threat = status.nearestThreat {
                    Text("\(threat.title) · \(threat.distanceText)")
                        .font(.app(.footnote, weight: .semibold))
                        .foregroundStyle(.alertRedInk)
                }
            }
            Spacer(minLength: 0)
            if let alert = status.alert {
                Badge("Тривога", tone: alert.level == .red ? .alertRed : .alertYellow)
            } else {
                Badge("Спокійно", tone: .allClear)
            }
        }
        .padding(Spacing.medium)
        .glassBackground(in: .rect(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private methods

private extension FeedHomeCard {

    var alertText: String {
        guard let alert = status.alert else { return "Тривоги немає" }
        return "Тривога \(DisplayTime.since(alert.startedAt, now: .now))"
    }
}
