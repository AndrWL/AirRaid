//
//  WidgetMessageView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI
import WidgetKit

/// What the widget says when it has no home status to show: a symbol, a title and what to do.
struct WidgetMessageView: View {

    // MARK: - Variables

    @Environment(\.widgetFamily) private var family
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(title, systemImage: systemImage)
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: systemImage)
                    .font(.app(.title3, weight: .semibold))
            }
        default:
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Image(systemName: systemImage)
                    .font(.app(.title3, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Spacer(minLength: 0)
                Text(title)
                    .font(.app(.headline, weight: .bold))
                    .foregroundStyle(Color.ink)
                Text(message)
                    .font(.app(.caption))
                    .foregroundStyle(Color.inkMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
