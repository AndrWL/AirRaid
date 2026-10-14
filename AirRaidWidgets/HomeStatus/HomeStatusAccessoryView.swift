//
//  HomeStatusAccessoryView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI
import WidgetKit

/// The lock screen widgets: tinted by the system, so the alert reads by words and symbols rather than by colour.
struct HomeStatusAccessoryView: View {

    // MARK: - Variables

    @Environment(\.widgetFamily) private var family
    let home: HomeStatus
    let entry: HomeStatusEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryInline: inline
        default: rectangular
        }
    }
}

// MARK: - Private methods

private extension HomeStatusAccessoryView {

    var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: Spacing.xxSmall) {
                Image(systemName: home.alert.systemImage)
                    .font(.app(.title3, weight: .semibold))
                    .widgetAccentable()
                Text(home.alert.shortTitle)
                    .font(.app(.caption2, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(Constants.minimumScale)
            }
            .padding(Spacing.xSmall)
        }
    }

    var inline: some View {
        Label {
            if let alert = home.alert {
                Text("Тривога \(WidgetTime.since(alert.startedAt, now: entry.date))")
            } else {
                Text("Тихо · \(home.placeName)")
            }
        } icon: {
            Image(systemName: home.alert.systemImage)
        }
    }

    var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: home.alert.systemImage)
                Text("\(home.alert.shortTitle) · \(home.placeName)")
                    .lineLimit(1)
            }
            .font(.app(.headline, weight: .bold))
            .widgetAccentable()
            if let alert = home.alert {
                Text("Триває \(WidgetTime.since(alert.startedAt, now: entry.date))")
                    .font(.app(.body, weight: .semibold))
            }
            if let threat = home.nearestThreat {
                Text("\(threat.title) · \(threat.distanceText)")
                    .font(.app(.caption))
                    .lineLimit(1)
            } else if home.alert != nil {
                Text("У радіусі \(Int(home.radiusKm)) км загроз немає")
                    .font(.app(.caption))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Constants

private enum Constants {
    static let minimumScale: CGFloat = 0.7
}
