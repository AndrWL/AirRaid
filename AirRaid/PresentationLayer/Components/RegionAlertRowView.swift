//
//  RegionAlertRowView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// A list row for one official alert: a level dot, the place and kind, and since when it lasts.
struct RegionAlertRowView: View {

    // MARK: - Variables

    private let row: RegionAlertRow

    init(_ row: RegionAlertRow) {
        self.row = row
    }

    var body: some View {
        HStack(spacing: Constants.spacing) {
            StatusDot(dotTone)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(row.name)
                    .foregroundStyle(.ink)
                if let kindText = row.kindText {
                    Text(kindText)
                        .font(.app(.footnote))
                        .foregroundStyle(.inkMuted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
                Text(row.startedText)
                    .foregroundStyle(.ink)
                Text(row.durationText)
                    .font(.app(.footnote))
                    .foregroundStyle(.inkMuted)
                    .contentTransition(.numericText())
                    .animation(Motion.quick, value: row.durationText)
            }
            .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private methods

private extension RegionAlertRowView {

    var dotTone: StatusDot.Tone {
        switch row.level {
        case .red: return .alertRed
        case .yellow: return .alertYellow
        case nil: return .unknown
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let spacing: CGFloat = 10
}

#Preview {
    List {
        RegionAlertRowView(RegionAlertRow(
            alert: RegionAlert(
                id: "1",
                kind: .airRaid,
                level: .red,
                scope: .raion,
                name: "Полтавський район",
                regionID: "UA-53",
                district: DistrictKey(regionID: "UA-53", name: "Полтавський"),
                startedAt: .now.addingTimeInterval(-4_500)
            ),
            now: .now
        ))
    }
}
