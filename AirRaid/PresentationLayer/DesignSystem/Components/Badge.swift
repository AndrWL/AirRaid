//
//  Badge.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// A capsule with a short state word: confidence, alert level, data state, or the "estimate" tag.
///
/// Confidence never borrows alert colours: its strength grows by fill (`neutral` → `accentSoft` → `accent`).
struct Badge: View {

    /// What the badge says, which decides its colours.
    enum Tone {
        /// Low confidence; the "estimate" tag.
        case neutral
        /// Medium confidence.
        case accentSoft
        /// High confidence.
        case accent
        case alertRed
        case alertYellow
        /// Stale data.
        case warning
        /// All clear.
        case allClear
    }

    /// How loud the badge is: a regular badge or the smaller tag next to a value.
    enum Size {
        case regular
        case tag
    }

    // MARK: - Variables

    private let text: String
    private let tone: Tone
    private let size: Size

    init(
        _ text: String,
        tone: Tone,
        size: Size = .regular
    ) {
        self.text = text
        self.tone = tone
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(size == .regular ? .app(.caption, weight: .semibold) : .app(.caption2, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .regular ? Spacing.small : Constants.tagHorizontalPadding)
            .padding(.vertical, size == .regular ? Constants.verticalPadding : Spacing.xxSmall)
            .background(background, in: .capsule)
    }
}

// MARK: - Factory

extension Badge {

    /// The tag next to a value the app computed rather than received, so it is not read as a fact.
    static var estimated: Badge {
        Badge("оцінка", tone: .neutral, size: .tag)
    }
}

// MARK: - Private methods

private extension Badge {

    var foreground: Color {
        switch tone {
        case .neutral: return .inkMuted
        case .accentSoft: return .accentInk
        case .accent: return .onAccent
        case .alertRed: return .alertRedInk
        case .alertYellow: return .alertYellowInk
        case .warning: return .warningInk
        case .allClear: return .allClearInk
        }
    }

    var background: Color {
        switch tone {
        case .neutral: return .surfaceSunken
        case .accentSoft: return .accentSoft
        case .accent: return .accentColor
        case .alertRed: return .alertRedSoft
        case .alertYellow: return .alertYellowSoft
        case .warning: return .warningSoft
        case .allClear: return .allClearSoft
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let verticalPadding: CGFloat = 3
    static let tagHorizontalPadding: CGFloat = 6
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.medium) {
        HStack {
            Badge("Достовірність: низька", tone: .neutral)
            Badge("Достовірність: середня", tone: .accentSoft)
            Badge("Достовірність: висока", tone: .accent)
        }
        HStack {
            Badge("Повітряна тривога", tone: .alertRed)
            Badge("Загроза", tone: .alertYellow)
            Badge("Застаріло", tone: .warning)
            Badge("Відбій", tone: .allClear)
            Badge.estimated
        }
    }
    .padding()
}
