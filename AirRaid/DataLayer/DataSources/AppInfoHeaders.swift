//
//  AppInfoHeaders.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// `X-App-Version`, `X-App-Build` and `X-OS-Version`, sent with every API request and WebSocket upgrade.
///
/// The backend records them per installation for diagnostics and answers `426 upgrade_required` when the version
/// is below its minimum.
nonisolated enum AppInfoHeaders {

    static func make(bundle: Bundle = .main) -> [String: String] {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return [
            Constants.appVersionHeader: bundle.object(forInfoDictionaryKey: Constants.versionKey) as? String ?? "",
            Constants.appBuildHeader: bundle.object(forInfoDictionaryKey: Constants.buildKey) as? String ?? "",
            Constants.osVersionHeader: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        ]
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let appVersionHeader = "X-App-Version"
    static let appBuildHeader = "X-App-Build"
    static let osVersionHeader = "X-OS-Version"
    static let versionKey = "CFBundleShortVersionString"
    static let buildKey = "CFBundleVersion"
}
