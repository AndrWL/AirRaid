//
//  AirRaidApp.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import SwiftUI

/// The main entry point of the application.
///
/// `AirRaidApp` bootstraps the SwiftUI lifecycle and connects the root view
/// to the dependency injection container hosted by the ``AppDelegate``.
@main
struct AirRaidApp: App {

    /// The app delegate adaptor used to handle UIKit lifecycle events and provide
    /// access to the root dependency injection container.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
