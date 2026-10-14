//
//  HomeStatusWidget.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI
import WidgetKit

/// Whether there is an air raid alert at the home (or, without a home, at the user's last location), how long it lasts
/// and the nearest threat in its radius; the medium size adds a mini-map of its oblast. Also on the lock screen.
struct HomeStatusWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: HomeStatusSnapshot.widgetKind, provider: HomeStatusProvider()) { entry in
            HomeStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Тривога вдома")
        .description("Тривога там, де ваш дім (або ви), і найближча загроза в радіусі.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
