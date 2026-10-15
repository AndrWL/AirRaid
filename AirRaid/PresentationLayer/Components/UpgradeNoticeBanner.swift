//
//  UpgradeNoticeBanner.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 15.10.2026.
//

import SwiftUI

/// The ``NoticeBanner`` for an ``UpgradeNotice``, over the map and atop the feed: update to see the situation again.
///
/// No close button: dismissing it would leave a screen that silently stopped updating.
struct UpgradeNoticeBanner: View {

    // MARK: - Variables

    let notice: UpgradeNotice

    var body: some View {
        NoticeBanner(
            systemImage: UpgradeNotice.systemImage,
            title: UpgradeNotice.title,
            subtitle: UpgradeNotice.subtitle,
            action: notice.appStoreURL.map { NoticeBanner.Action(title: UpgradeNotice.actionTitle, url: $0) }
        )
    }
}

#Preview {
    VStack(spacing: Spacing.large) {
        UpgradeNoticeBanner(notice: UpgradeNotice(appStoreURL: URL(string: "https://apps.apple.com")))
        UpgradeNoticeBanner(notice: UpgradeNotice(appStoreURL: nil))
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
    .preferredColorScheme(.dark)
}
