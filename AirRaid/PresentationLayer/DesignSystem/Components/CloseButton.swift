//
//  CloseButton.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The round glass `xmark` button in the top trailing corner of a sheet.
struct CloseButton: View {

    // MARK: - Variables

    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button("Закрити", systemImage: "xmark", action: action)
            .labelStyle(.iconOnly)
            .font(.app(.body, weight: .semibold))
            .foregroundStyle(.ink)
            .glassButtonStyle()
            .buttonBorderShape(.circle)
    }
}

// MARK: - View

extension View {

    /// Pins a ``CloseButton`` above the sheet's scrolling content, on a strip of the sheet's background: rows scroll
    /// under the strip instead of under the button and the grabber.
    func sheetCloseBar(action: @escaping () -> Void) -> some View {
        // The bar already keeps the content off the sheet's top edge.
        contentMargins(.top, Spacing.xSmall, for: .scrollContent)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Spacer()
                    CloseButton(action: action)
                }
                .padding(.horizontal, Spacing.large)
                .padding(.top, Spacing.large)
                .padding(.bottom, Spacing.xSmall)
                .background(Color.appBackground)
            }
    }
}

#Preview {
    CloseButton {}
        .padding()
}
