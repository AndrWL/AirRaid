//
//  SheetPresenting.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 24.04.2026.
//

import Foundation

/// A protocol for managing sheet presentation.
///
/// Conforming types hold an optional `activeSheet` that drives `.sheet(item:)` in SwiftUI.
/// The associated `SheetRoute` type defines all possible sheets a router can present.
///
/// Default implementations for `presentSheet(_:)` and `dismissSheet()` are provided.
///
/// ## Defining sheet routes
///
/// ```swift
/// enum HomeSheet: Identifiable, Hashable {
///     case filter
///     case sort
///
///     var id: Self { self }
///
///     var detents: Set<PresentationDetent> {
///         switch self {
///         case .filter: [.medium, .large]
///         case .sort: [.medium]
///         }
///     }
/// }
/// ```
///
/// ## Conformance
///
/// ```swift
/// @Observable
/// final class HomeRouter: SheetPresenting {
///     var activeSheet: HomeSheet?
/// }
/// ```
protocol SheetPresenting: AnyObject, Observable {
    
    /// The type defining the possible sheet routes that can be presented.
    /// It must conform to `Identifiable` to work seamlessly with SwiftUI's `.sheet(item:)` modifier.
    associatedtype SheetRoute: Identifiable
    
    /// The currently active sheet route.
    ///
    /// When this value is set to a specific route, the corresponding sheet is presented.
    /// Setting this value to `nil` dismisses the current sheet.
    var activeSheet: SheetRoute? { get set }
    
    /// Presents the specified sheet route.
    ///
    /// - Parameter route: The `SheetRoute` to present.
    func presentSheet(_ route: SheetRoute)
    
    /// Dismisses the currently presented sheet.
    ///
    /// This method hides the active sheet by setting `activeSheet` to `nil`.
    func dismissSheet()
}

extension SheetPresenting {
    
    func presentSheet(_ route: SheetRoute) {
        activeSheet = route
    }
    
    func dismissSheet() {
        activeSheet = nil
    }
}
