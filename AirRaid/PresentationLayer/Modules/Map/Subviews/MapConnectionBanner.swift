//
//  MapConnectionBanner.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The ``NoticeBanner`` for a ``MapConnectionNotice``: the map is not live, and since when.
struct MapConnectionBanner: View {

    // MARK: - Variables

    let notice: MapConnectionNotice

    var body: some View {
        NoticeBanner(
            systemImage: notice.systemImage,
            title: notice.title,
            subtitle: notice.subtitle,
            isPulsing: notice.isInProgress
        )
    }
}

#Preview {
    VStack(spacing: Spacing.large) {
        MapConnectionBanner(notice: .connecting(since: nil))
        MapConnectionBanner(notice: .offline(since: .now))
        MapConnectionBanner(notice: .upgradeRequired)
    }
    .padding()
    .background(.black)
    .preferredColorScheme(.dark)
}
