//
//  AppGroup.swift
//  HomeStatusKit
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// The App Group the app and its widget extension share.
///
/// Named after the app's bundle identifier (`group.com.andriilebediev.airraid.dev` for the Debug app), so the Debug and
/// Release apps installed side by side never read each other's data. Both entitlements files must list the same name.
public enum AppGroup {

    /// The group of the running app, or of the app that embeds the running extension.
    public static var identifier: String {
        identifier(
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            isExtension: Bundle.main.bundleURL.pathExtension == Constants.extensionPathExtension
        )
    }

    /// `group.` + the app's bundle identifier; an extension's own identifier (`<app>.widgets`) loses its last part.
    public static func identifier(
        bundleIdentifier: String,
        isExtension: Bool
    ) -> String {
        guard isExtension, let dot = bundleIdentifier.lastIndex(of: ".") else {
            return Constants.prefix + bundleIdentifier
        }
        return Constants.prefix + bundleIdentifier[..<dot]
    }
}

// MARK: - Constants

private enum Constants {
    static let prefix = "group."
    static let extensionPathExtension = "appex"
}
