//
//  HomeStatusSmallView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The small widget, and the left half of the medium one: the place, the alert with its start, the nearest threat.
struct HomeStatusSmallView: View {

    // MARK: - Variables

    let home: HomeStatus
    let entry: HomeStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            placeLine
            Spacer(minLength: 0)
            statusBlock
            Spacer(minLength: 0)
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Private methods

private extension HomeStatusSmallView {

    var placeLine: some View {
        Label(home.placeName, systemImage: home.placeKind.systemImage)
            .font(.app(.caption, weight: .semibold))
            .foregroundStyle(Color.inkMuted)
            .lineLimit(1)
    }

    var statusBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack(spacing: Spacing.xSmall) {
                StatusDot(home.alert.dotTone)
                Text(home.alert.shortTitle)
                    .font(.app(.headline, weight: .bold))
                    .foregroundStyle(Color.ink)
            }
            if let alert = home.alert {
                Text(WidgetTime.since(alert.startedAt, now: entry.date))
                    .font(.app(.title2, weight: .bold))
                    .foregroundStyle(alert.level.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(Constants.minimumScale)
            } else {
                Text("Тривоги немає")
                    .font(.app(.footnote))
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    @ViewBuilder
    var footer: some View {
        if entry.isStale, let updatedAt = entry.updatedAt {
            Text("Дані від \(updatedAt.formatted(WidgetTime.clockStyle))")
                .font(.app(.caption2, weight: .semibold))
                .foregroundStyle(Color.warningInk)
        } else if let threat = home.nearestThreat {
            NearThreatRow(threat: threat, placeKind: home.placeKind, now: entry.date, style: .compact)
        } else if let threat = home.closestThreat {
            // Said in words, as in the Live Activity: the muted icon alone reads like a threat inside the radius.
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Поза радіусом \(Int(home.radiusKm)) км")
                    .font(.app(.caption2))
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(1)
                NearThreatRow(threat: threat, placeKind: home.placeKind, now: entry.date, style: .compact, tone: .outside)
            }
        } else {
            Text("У радіусі \(Int(home.radiusKm)) км загроз немає")
                .font(.app(.caption2))
                .foregroundStyle(Color.inkMuted)
                .lineLimit(2)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let minimumScale: CGFloat = 0.7
}
