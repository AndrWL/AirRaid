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

    /// The live connection, started once the main flow is on screen and kept for the rest of the session.
    @ObservationIgnored
    private let realtimeService: RealtimeServiceProtocol

    /// Keeps the widgets and the Live Activity in step with the home; follows the connection for the whole session.
    @ObservationIgnored
    private let homeStatusBroadcaster: HomeStatusBroadcasting

    /// Initializes the view model with its required router.
    ///
    /// - Parameters:
    ///   - router: An object conforming to `TabBarRouterProtocol`.
    ///   - realtimeService: The live connection every tab reads from.
    ///   - homeStatusBroadcaster: Feeds the widgets and the Live Activity from the same connection.
    init(
        router: TabBarRouterProtocol,
        realtimeService: RealtimeServiceProtocol,
        homeStatusBroadcaster: HomeStatusBroadcasting
    ) {
        self.router = router
        self.realtimeService = realtimeService
        self.homeStatusBroadcaster = homeStatusBroadcaster
    }
}

// MARK: - TabBarViewModelProtocol

extension TabBarViewModel: TabBarViewModelProtocol {

    func onAppear() {
        // Idempotent; the service pauses in the background on its own.
        realtimeService.start()
        homeStatusBroadcaster.start()
    }
}
