//
//  MapConnectionBanner.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// A compact capsule over the map saying that it is not live and since when.
struct MapConnectionBanner: View {

    // MARK: - Variables

    let notice: MapConnectionNotice

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: notice.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text(notice.title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle = notice.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .bannerBackground()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - View

private extension View {

    /// Liquid Glass on iOS 26, a material capsule before it.
    @ViewBuilder
    func bannerBackground() -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: .capsule)
        } else {
            background(.regularMaterial, in: .capsule)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MapConnectionBanner(notice: .connecting(since: nil))
        MapConnectionBanner(notice: .offline(since: .now))
        MapConnectionBanner(notice: .upgradeRequired)
    }
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
