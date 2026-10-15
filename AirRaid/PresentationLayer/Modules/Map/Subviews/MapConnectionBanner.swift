//
//  MapConnectionBanner.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The ``NoticeBanner`` for a ``MapConnectionNotice``: the map is not live, and since when — or, for a refused
/// version, the ``UpgradeNoticeBanner`` the feed shows too.
struct MapConnectionBanner: View {

    // MARK: - Variables

    let notice: MapConnectionNotice

    /// The App Store page for the update button; used only by ``MapConnectionNotice/upgradeRequired``.
    var appStoreURL: URL?

    var body: some View {
        Group {
            switch notice {
            case .upgradeRequired:
                UpgradeNoticeBanner(notice: UpgradeNotice(appStoreURL: appStoreURL))
            case .connecting, .offline:
                NoticeBanner(
                    systemImage: notice.systemImage,
                    title: notice.title,
                    subtitle: notice.subtitle,
                    isPulsing: notice.isInProgress
                )
            }
        }
        // The update prompt wraps to two lines; keep it off the screen edges.
        .padding(.horizontal, Spacing.large)
    }
}

#Preview {
    VStack(spacing: Spacing.large) {
        MapConnectionBanner(notice: .connecting(since: nil))
        MapConnectionBanner(notice: .offline(since: .now))
        MapConnectionBanner(notice: .upgradeRequired)
        MapConnectionBanner(notice: .upgradeRequired, appStoreURL: URL(string: "https://apps.apple.com"))
    }
    .padding(.vertical)
    .background(.black)
    .preferredColorScheme(.dark)
}
