//
//  AppVersionInfo.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// The app's version and build and the iOS version, for the settings and the feedback email.
struct AppVersionInfo: Hashable {

    /// «1.2».
    let version: String

    /// «34».
    let build: String

    /// «26.0.1».
    let osVersion: String

    /// «1.2 (34)».
    var displayText: String {
        build.isEmpty ? version : "\(version) (\(build))"
    }

    static func current(bundle: Bundle = .main) -> AppVersionInfo {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return AppVersionInfo(
            version: bundle.object(forInfoDictionaryKey: Constants.versionKey) as? String ?? "",
            build: bundle.object(forInfoDictionaryKey: Constants.buildKey) as? String ?? "",
            osVersion: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let versionKey = "CFBundleShortVersionString"
    static let buildKey = "CFBundleVersion"
}
