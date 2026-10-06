//
//  BaseViewModelProtocol.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation

/// Base protocol for all ViewModels in the application.
///
/// Provides a common contract that all ViewModel protocols extend.
/// Requires `Observable` conformance for SwiftUI observation
/// and `AnyObject` to ensure reference semantics.
///
/// Feature ViewModel protocols should extend this:
///
/// ```swift
/// protocol HomeViewModelProtocol: BaseViewModelProtocol {
///     var items: [Item] { get }
///     func onItemTapped(id: String)
/// }
/// ```
@MainActor
protocol BaseViewModelProtocol: Observable, AnyObject {

}
