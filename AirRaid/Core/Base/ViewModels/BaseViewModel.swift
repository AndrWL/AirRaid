//
//  BaseViewModel.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 27.04.2026.
//

import Foundation
import Combine

/// Base class for all ViewModels in the application.
///
/// Provides shared infrastructure for Combine subscriptions via `cancellables`.
/// All subclasses automatically conform to ``BaseViewModelProtocol``
/// and run on `@MainActor`.
///
/// ## Subclassing
///
/// ```swift
/// @Observable
/// final class HomeViewModel: BaseViewModel {
///     private(set) var items: [Item] = []
/// }
/// ```
@MainActor @Observable
class BaseViewModel {
    
    // MARK: - Variables
    
    /// A collection used to store and manage Combine subscriptions.
    ///
    /// Storing `AnyCancellable` instances in this set ensures that active subscriptions
    /// are automatically canceled and deallocated when the view model is deinitialized.
    /// It is marked with `@ObservationIgnored` because SwiftUI does not need to track
    /// changes to this collection for UI updates.
    @ObservationIgnored
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        setupBindings()
    }
    
    // MARK: - Methods
    
    /// A lifecycle hook for setting up reactive bindings.
    ///
    /// This method is intended to be overridden by subclasses to configure Combine
    /// subscriptions, listen to services, and bind state updates. The default
    /// implementation does nothing.
    func setupBindings() { }
}

// MARK: - BaseViewModelProtocol

extension BaseViewModel: BaseViewModelProtocol {
    
}
