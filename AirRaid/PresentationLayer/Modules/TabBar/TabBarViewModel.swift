//
//  TabBarViewModel.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import Foundation

/// The view model responsible for managing the logic of the tab bar container.
///
/// `TabBarViewModel` acts as the intermediary between the `TabBarView` and the `TabBarRouter`,
/// keeping the UI isolated from the raw navigation mechanics.
@Observable
final class TabBarViewModel: BaseViewModel {
    
    /// The router responsible for executing tab switching and managing global navigation state.
    @ObservationIgnored
    private let router: TabBarRouterProtocol
    
    /// Initializes the view model with its required router.
    ///
    /// - Parameter router: An object conforming to `TabBarRouterProtocol`.
    init(
        router: TabBarRouterProtocol
    ) {
        self.router = router
    }
}

// MARK: - TabBarViewModelProtocol

extension TabBarViewModel: TabBarViewModelProtocol {
    
}
