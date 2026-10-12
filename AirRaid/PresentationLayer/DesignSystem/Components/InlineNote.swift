//
//  InlineNote.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// A glyph and one sentence inside a section: a limit of the data, or an empty state.
struct InlineNote: View {

    /// What the note is about.
    enum Tone {
        /// Stale data, an imprecise position, a threat without an official alert.
        case warning
        /// An all-clear empty state such as «Тривоги немає».
        case allClear
    }

    // MARK: - Variables

    private let text: String
    private let systemImage: String
    private let tone: Tone

    init(
        _ text: String,
        systemImage: String,
        tone: Tone
    ) {
        self.text = text
        self.systemImage = systemImage
        self.tone = tone
    }

    var body: some View {
        Label {
            Text(text)
                .foregroundStyle(tone == .warning ? Color.warningInk : .inkMuted)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tone == .warning ? Color.warning : .allClear)
        }
        .font(tone == .warning ? .app(.footnote, weight: .medium) : .app(.body))
    }
}

#Preview {
    List {
        InlineNote("Даних не було 12 хв", systemImage: "clock.badge.exclamationmark", tone: .warning)
        InlineNote("Розташування приблизне", systemImage: "exclamationmark.triangle", tone: .warning)
        InlineNote("Тривоги немає", systemImage: "checkmark.shield", tone: .allClear)
    }
}
