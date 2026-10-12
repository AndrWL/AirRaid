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

#Preview {
    CloseButton {}
        .padding()
}
