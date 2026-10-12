//
//  RegionFocusPill.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// Says the map is narrowed to one region: a tap brings the camera back onto it, the cross shows the whole country.
struct RegionFocusPill: View {

    // MARK: - Variables

    let regionName: String
    let onRecenter: () -> Void
    let onExit: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Button(action: onRecenter) {
                Label(regionName, systemImage: "scope")
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(.ink)
                    .padding(.leading, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Фокус: \(regionName)")
            .accessibilityHint("Повернути карту на область")

            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.app(.footnote, weight: .bold))
                    .foregroundStyle(.inkMuted)
                    .frame(width: Constants.exitButtonSize, height: Constants.exitButtonSize)
                    .contentShape(.rect)
            }
            .padding(.trailing, Spacing.xSmall)
            .accessibilityLabel("Показати всю Україну")
        }
        .buttonStyle(.plain)
        .glassBackground(in: .capsule)
        // The gaps between the two buttons belong to the pill, not to the map below it.
        .contentShape(.capsule)
    }
}

// MARK: - Constants

private enum Constants {
    static let exitButtonSize: CGFloat = 32
}

#Preview {
    RegionFocusPill(regionName: "Полтавська область", onRecenter: {}, onExit: {})
        .padding()
        .background(.black)
        .preferredColorScheme(.dark)
}
