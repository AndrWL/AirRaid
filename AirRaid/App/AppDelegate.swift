//
//  AppDelegate.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 22.04.2026.
//

import Foundation
import UIKit

/// The application delegate responsible for managing app lifecycle and root-level dependencies.
///
/// `AppDelegate` is the single owner of the DI container and the app configurator.
/// It is connected to SwiftUI via `@UIApplicationDelegateAdaptor` in ``AirRaid``.
///
/// ## Startup sequence
///
/// `application(_:didFinishLaunchingWithOptions:)` executes two steps in order:
///
/// 1. **`AppConfigurator.configure()`** — initializes third-party SDKs (Firebase, analytics, etc.).
///    Must run first because DI factories may depend on configured SDKs.
/// 2. **`DIAppContainer.setup()`** — registers all dependencies in the DI graph.
///
/// ## Accessing the DI container
///
/// SwiftUI views access the container through the delegate:
///
/// ```swift
/// @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
/// let services = delegate.appContainer.services
/// ```
class AppDelegate: NSObject, UIApplicationDelegate {
    
    /// The root dependency injection container for the application.
    /// It holds all shared services, repositories, and configurations.
    let appContainer: DIAppContaining = DIAppContainer()
    
    /// The configurator responsible for setting up third-party tools, SDKs,
    /// and global application appearance upon launch.
    private let appConfigurator = AppConfigurator()
    
    /// Tells the delegate that the launch process is almost done and the app is almost ready to run.
    ///
    /// This method is used to execute the initial setup sequence, configuring SDKs first
    /// and then registering dependencies in the DI container.
    ///
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - launchOptions: A dictionary indicating the reason the app was launched (if any).
    /// - Returns: `true` if the app was launched successfully.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        appConfigurator.configure()
        appContainer.setup()
        return true
    }
}
