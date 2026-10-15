//
//  UpgradeNotice.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 15.10.2026.
//

import Foundation

/// The prompt to update the app once the server refuses this version (``RealtimeConnectionState/upgradeRequired``).
///
/// The map, the feed and the settings say it in the same words. It cannot be dismissed: until the update nothing on
/// screen changes again, and without the prompt that would look exactly like a quiet sky.
struct UpgradeNotice: Equatable {

    // MARK: - Variables

    static let title = "Оновіть AirRaid, щоб бачити обстановку"

    static let subtitle = "Ця версія більше не отримує нових даних"

    /// For the settings, under the version.
    static let versionNote = "Ця версія застаріла. Оновіть AirRaid, щоб бачити обстановку"

    static let actionTitle = "Оновити"

    static let systemImage = "arrow.down.app"

    /// The App Store page; `nil` while the app has no App Store ID, which hides the button.
    let appStoreURL: URL?

    init(appStoreURL: URL?) {
        self.appStoreURL = appStoreURL
    }

    /// The notice to show once the connection reaches `state`, given the one shown before.
    ///
    /// Every return to the foreground re-checks the version: `connecting`, then `426` again. The prompt stays through
    /// that attempt instead of blinking off for a second; only a connection the server accepts clears it.
    ///
    /// - Parameters:
    ///   - current: The notice shown now, `nil` if none.
    ///   - state: The new connection state.
    ///   - appStoreURL: The App Store page for the button; `nil` hides it.
    /// - Returns: A notice for ``RealtimeConnectionState/upgradeRequired``, `nil` once connected, else `current`.
    static func next(
        after current: UpgradeNotice?,
        state: RealtimeConnectionState,
        appStoreURL: URL?
    ) -> UpgradeNotice? {
        switch state {
        case .upgradeRequired:
            return UpgradeNotice(appStoreURL: appStoreURL)
        case .connected:
            return nil
        case .connecting, .disconnected, .waitingForNetwork:
            return current
        }
    }
}
