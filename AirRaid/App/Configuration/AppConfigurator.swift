//
//  AppConfigurator.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

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

    }
}
