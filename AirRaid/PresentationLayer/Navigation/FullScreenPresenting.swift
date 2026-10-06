//
//  FullScreenPresenting.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 24.04.2026.
//

import Foundation

/// A protocol for managing full-screen cover presentation.
///
/// Conforming types hold an optional `activeFullScreen` that drives
/// `.fullScreenCover(item:)` in SwiftUI. The associated `FullScreenRoute` type
/// defines all possible full-screen covers a router can present.
///
/// Default implementations for `presentFullScreen(_:)` and `dismissFullScreen()` are provided.
///
/// ## Conformance
///
/// ```swift
/// @Observable
/// final class OnboardingRouter: FullScreenPresenting {
///     var activeFullScreen: OnboardingCover?
/// }
/// ```
protocol FullScreenPresenting: AnyObject, Observable {
    
    /// The type defining the possible full-screen routes that can be presented.
    /// It must conform to `Identifiable` to work seamlessly with SwiftUI's `.fullScreenCover(item:)` modifier.
    associatedtype FullScreenRoute: Identifiable
    
    /// The currently active full-screen route.
    ///
    /// When this value is set to a specific route, the corresponding full-screen cover is presented.
    /// Setting this value to `nil` dismisses the current full-screen cover.
    var activeFullScreen: FullScreenRoute? { get set }
    
    /// Presents the specified full-screen route.
    ///
    /// - Parameter route: The `FullScreenRoute` to present.
    func presentFullScreen(_ route: FullScreenRoute)
    
    /// Dismisses the currently presented full-screen cover.
    ///
    /// This method hides the active full-screen view by setting `activeFullScreen` to `nil`.
    func dismissFullScreen()
}

extension FullScreenPresenting {
    
    func presentFullScreen(_ route: FullScreenRoute) {
        activeFullScreen = route
    }
    
    func dismissFullScreen() {
        activeFullScreen = nil
    }
}
