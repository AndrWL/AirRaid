//
//  HomeStatusWidgetView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI
import WidgetKit

/// Picks the layout for the widget's size, or a message when there is nothing to show yet.
struct HomeStatusWidgetView: View {

    // MARK: - Variables

    @Environment(\.widgetFamily) private var family
    let entry: HomeStatusEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if !isAccessory {
                    Color.surface
                }
            }
    }
}

// MARK: - Private methods

private extension HomeStatusWidgetView {

    var isAccessory: Bool {
        [.accessoryCircular, .accessoryRectangular, .accessoryInline].contains(family)
    }

    @ViewBuilder
    var content: some View {
        switch (entry.content, family) {
        case (.home(let home), .systemMedium):
            HomeStatusMediumView(home: home, entry: entry)
        case (.home(let home), .accessoryCircular), (.home(let home), .accessoryRectangular), (.home(let home), .accessoryInline):
            HomeStatusAccessoryView(home: home, entry: entry)
        case (.home(let home), _):
            HomeStatusSmallView(home: home, entry: entry)
        case (.noPlace, _):
            WidgetMessageView(
                systemImage: "house",
                title: "Немає місця",
                message: "Позначте дім на мапі або дозвольте геолокацію в AirRaid"
            )
        case (.noData, _):
            WidgetMessageView(
                systemImage: "antenna.radiowaves.left.and.right",
                title: "Немає даних",
                message: "Відкрийте AirRaid, щоб віджет ожив"
            )
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    HomeStatusWidget()
} timeline: {
    HomeStatusEntry(date: .now, snapshot: .previewAlert)
    HomeStatusEntry(date: .now, snapshot: .previewCalm)
    HomeStatusEntry(date: .now.addingTimeInterval(3_600), snapshot: .previewCalm)
    HomeStatusEntry(date: .now, snapshot: HomeStatusSnapshot(updatedAt: .now, home: nil))
    HomeStatusEntry(date: .now, snapshot: nil)
}

#Preview("Medium", as: .systemMedium) {
    HomeStatusWidget()
} timeline: {
    HomeStatusEntry(date: .now, snapshot: .previewAlert)
    HomeStatusEntry(date: .now, snapshot: .previewCalm)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    HomeStatusWidget()
} timeline: {
    HomeStatusEntry(date: .now, snapshot: .previewAlert)
    HomeStatusEntry(date: .now, snapshot: .previewCalm)
}

#Preview("Circular", as: .accessoryCircular) {
    HomeStatusWidget()
} timeline: {
    HomeStatusEntry(date: .now, snapshot: .previewAlert)
    HomeStatusEntry(date: .now, snapshot: .previewCalm)
}

#Preview("Inline", as: .accessoryInline) {
    HomeStatusWidget()
} timeline: {
    HomeStatusEntry(date: .now, snapshot: .previewAlert)
}
