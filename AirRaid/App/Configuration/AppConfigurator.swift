//
//  AppConfigurator.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import SwiftUI
import UIKit

/// Configures the application environment at launch.
///
/// `AppConfigurator` is called once from ``AppDelegate/application(_:didFinishLaunchingWithOptions:)``
/// **before** the DI container is set up. This guarantees that all configured services are ready
/// by the time dependency factories start resolving.
///
/// ## Responsibilities
///
/// - Third-party SDKs (analytics, crash reporting, etc.)
/// - Global app appearance (navigation bar, tab bar, fonts)
/// - Logging and diagnostics setup
///
/// ## Adding a new configuration step
///
/// 1. Create a private method (e.g., `configureAppearance()`).
/// 2. Call it from `configure()`.
struct AppConfigurator {

    func configure() {
        configureAppearance()
    }
}

// MARK: - Private methods

private extension AppConfigurator {

    /// Sets the app typeface on the UIKit bars SwiftUI cannot style: navigation titles and tab items.
    func configureAppearance() {
        AppFont.register()

        let navigationBar = UINavigationBar.appearance()
        navigationBar.titleTextAttributes = [
            .font: AppFont.uiFont(.headline, size: AppFont.size(of: .headline), weight: .bold)
        ]
        navigationBar.largeTitleTextAttributes = [
            .font: AppFont.uiFont(.largeTitle, size: AppFont.size(of: .largeTitle), weight: .heavy)
        ]

        let tabItem = UITabBarItem.appearance()
        let tabFont = AppFont.uiFont(.caption2, size: Constants.tabItemFontSize, weight: .semibold)
        tabItem.setTitleTextAttributes([.font: tabFont], for: .normal)
        tabItem.setTitleTextAttributes([.font: tabFont], for: .selected)
    }
}

// MARK: - Constants

private enum Constants {
    static let tabItemFontSize: CGFloat = 10
}
