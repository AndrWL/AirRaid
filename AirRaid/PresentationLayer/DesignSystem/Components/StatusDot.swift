//
//  StatusDot.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// A dot marking an alert level at the start of a row. Always paired with the level's or the place's name.
struct StatusDot: View {

    /// The level the dot shows.
    enum Tone {
        case alertRed
        case alertYellow
        case allClear
        /// The level is not known: an outline only.
        case unknown
    }

    // MARK: - Variables

    @Environment(\.colorScheme) private var colorScheme
    private let tone: Tone

    init(_ tone: Tone) {
        self.tone = tone
    }

    var body: some View {
        Circle()
            .fill(fill)
            .overlay {
                if let ring {
                    Circle().strokeBorder(ring, lineWidth: Constants.ringWidth)
                }
            }
            .frame(width: Constants.size, height: Constants.size)
            .accessibilityHidden(true)
    }
}

// MARK: - Private methods

private extension StatusDot {

    var fill: Color {
        switch tone {
        case .alertRed: return .alertRed
        case .alertYellow: return .alertYellow
        case .allClear: return .allClear
        case .unknown: return .clear
        }
    }

    /// Yellow is 2:1 on a light surface, so it gets a dark rim there; an unknown level is the rim alone.
    var ring: Color? {
        switch tone {
        case .alertYellow: return colorScheme == .light ? .alertYellowInk : nil
        case .unknown: return .inkMuted
        case .alertRed, .allClear: return nil
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let size: CGFloat = 10
    static let ringWidth: CGFloat = 1
}

#Preview {
    HStack(spacing: Spacing.large) {
        StatusDot(.alertRed)
        StatusDot(.alertYellow)
        StatusDot(.allClear)
        StatusDot(.unknown)
    }
    .padding()
}
