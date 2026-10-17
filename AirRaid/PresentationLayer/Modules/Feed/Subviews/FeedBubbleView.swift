//
//  FeedBubbleView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// One bubble: the threat or alert, its current state, the distance to the user's place, and the lines it gathered.
struct FeedBubbleView: View {

    // MARK: - Variables

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let row: FeedRow
    private let onReadAloud: () -> Void

    init(
        row: FeedRow,
        onReadAloud: @escaping () -> Void
    ) {
        self.row = row
        self.onReadAloud = onReadAloud
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            header
            if let proximityText = row.proximityText {
                Label(proximityText, systemImage: "location.north.line")
                    .font(.app(.footnote, weight: .semibold))
                    .foregroundStyle(row.tone == .critical ? Color.alertRedInk : Color.accentInk)
            }
            linesList
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: .rect(cornerRadius: Radius.large))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.large)
                .strokeBorder(border, lineWidth: row.tone == .critical ? 1.5 : 0.5)
        }
        .opacity(row.tone == .quiet ? Constants.quietOpacity : 1)
        .contextMenu {
            Button(action: onReadAloud) {
                Label("Прочитати вголос", systemImage: "speaker.wave.2")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Прочитати вголос", onReadAloud)
    }
}

// MARK: - Sections

private extension FeedBubbleView {

    /// The icon, title and time in a row; at the largest text sizes the title gets a line of its own, or its words
    /// would break mid-word.
    @ViewBuilder
    var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(alignment: .top, spacing: Spacing.small) {
                    icon
                    Spacer(minLength: Spacing.small)
                    timeColumn
                }
                titles
            }
        } else {
            HStack(alignment: .top, spacing: Spacing.small) {
                icon
                titles
                Spacer(minLength: Spacing.small)
                timeColumn
            }
        }
    }

    var titles: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(row.title)
                .font(.app(.headline, weight: .bold))
                .foregroundStyle(.ink)
            if let subtitle = row.subtitle {
                Text(subtitle)
                    .font(.app(.subheadline))
                    .foregroundStyle(.inkMuted)
            }
        }
    }

    var timeColumn: some View {
        VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
            Text(row.timeText)
                .font(.app(.caption))
                .foregroundStyle(.inkMuted)
            if row.isActive {
                StatusDot(row.tone == .normal ? .alertYellow : .alertRed)
                    .accessibilityLabel("Триває")
            }
        }
    }

    @ViewBuilder
    var icon: some View {
        if let iconName = row.iconName {
            // The map's silhouettes are white for the dark map; here they take the text colour.
            Image(iconName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(row.tone == .critical ? Color.alertRedInk : Color.ink)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .accessibilityHidden(true)
        } else if let systemImage = row.systemImage {
            Image(systemName: systemImage)
                .font(.app(.title3, weight: .semibold))
                .foregroundStyle(row.tone == .allClear ? Color.allClearInk : Color.alertRedInk)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .accessibilityHidden(true)
        }
    }

    var linesList: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            if let droppedLinesText = row.droppedLinesText {
                Text(droppedLinesText)
                    .font(.app(.caption))
                    .foregroundStyle(.inkMuted)
            }
            ForEach(row.lines) { line in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    Text(line.timeText)
                        .font(.app(.caption, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.inkMuted)
                    Text(line.text)
                        .font(.app(.footnote))
                        .foregroundStyle(.ink)
                }
            }
        }
    }

    var background: Color {
        switch row.tone {
        case .critical: .alertRedSoft
        case .high: .alertYellowSoft
        case .allClear: .allClearSoft
        case .normal, .quiet: .surface
        }
    }

    var border: Color {
        switch row.tone {
        case .critical: .alertRed
        case .high: .alertYellow
        case .normal, .quiet, .allClear: .hairline
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let iconSize: CGFloat = 28
    static let quietOpacity: Double = 0.75
}

#Preview {
    let now = Date()
    let item = FeedItem(
        id: "threat:1",
        createdAt: now.addingTimeInterval(-900),
        updatedAt: now,
        isActive: true,
        priority: .normal,
        regionIDs: ["UA-74", "UA-32"],
        lines: [
            FeedLine(
                date: now.addingTimeInterval(-900),
                event: .threatAppeared(regionName: "Чернігівська область", positionName: "Ніжин", targetName: "Бровари")
            ),
            FeedLine(date: now.addingTimeInterval(-300), event: .threatCrossedRegion(regionName: "Київська область"))
        ],
        droppedLineCount: 0,
        content: .threat(FeedThreat(
            threatID: "1",
            kind: .drone,
            type: .shahed,
            count: 3,
            level: .high,
            regionID: "UA-32",
            regionName: "Київська область",
            positionName: "Бровари",
            targetName: "Київ",
            isCountryWide: false
        ))
    )
    ScrollView {
        FeedBubbleView(row: FeedRow(item: item, threat: nil, places: [], now: now)) { }
            .padding()
    }
    .background(Color.appBackground)
}
