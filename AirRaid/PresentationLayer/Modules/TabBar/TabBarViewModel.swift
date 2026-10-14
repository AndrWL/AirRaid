//
//  TabBarViewModel.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 01.05.2026.
//

import Combine
import Foundation

/// The view model responsible for managing the logic of the tab bar container.
///
/// `TabBarViewModel` acts as the intermediary between the `TabBarView` and the `TabBarRouter`,
/// keeping the UI isolated from the raw navigation mechanics.
@Observable
final class TabBarViewModel: BaseViewModel {

    private(set) var unreadFeedCount = 0
    
    /// The router responsible for executing tab switching and managing global navigation state.
    @ObservationIgnored
    private let router: TabBarRouterProtocol

    /// The live connection, started once the main flow is on screen and kept for the rest of the session.
    @ObservationIgnored
    private let realtimeService: RealtimeServiceProtocol

    /// Keeps the widgets and the Live Activity in step with the home; follows the connection for the whole session.
    @ObservationIgnored
    private let homeStatusBroadcaster: HomeStatusBroadcasting

    /// The feed is built here for the whole session, so it misses nothing while its tab is closed.
    @ObservationIgnored
    private let feedRepository: FeedRepositoryProtocol

    /// Listens for App Store transactions from launch, so a renewal or a refund is never missed.
    @ObservationIgnored
    private let entitlementService: EntitlementServiceProtocol

    /// Initializes the view model with its required router.
    ///
    /// - Parameters:
    ///   - router: An object conforming to `TabBarRouterProtocol`.
    ///   - realtimeService: The live connection every tab reads from.
    ///   - homeStatusBroadcaster: Feeds the widgets and the Live Activity from the same connection.
    ///   - feedRepository: The feed, started with the connection; also the source of the tab's badge.
    ///   - entitlementService: AirRaid Плюс, started at launch.
    init(
        router: TabBarRouterProtocol,
        realtimeService: RealtimeServiceProtocol,
        homeStatusBroadcaster: HomeStatusBroadcasting,
        feedRepository: FeedRepositoryProtocol,
        entitlementService: EntitlementServiceProtocol
    ) {
        self.router = router
        self.realtimeService = realtimeService
        self.homeStatusBroadcaster = homeStatusBroadcaster
        self.feedRepository = feedRepository
        self.entitlementService = entitlementService
        super.init()
    }
}

// MARK: - TabBarViewModelProtocol

extension TabBarViewModel: TabBarViewModelProtocol {

    func onAppear() {
        // Idempotent; the service pauses in the background on its own.
        realtimeService.start()
        homeStatusBroadcaster.start()
        feedRepository.start()
        entitlementService.start()
        bindUnreadCount()
    }
}

// MARK: - Private methods

private extension TabBarViewModel {

    /// Bubbles changed after the last visit and still within the free history — what the user would scroll to.
    func bindUnreadCount() {
        guard cancellables.isEmpty else { return }
        feedRepository.itemsPublisher
            .combineLatest(feedRepository.lastReadAtPublisher)
            .map { items, lastReadAt in
                let since = max(lastReadAt ?? .distantPast, Date().addingTimeInterval(-PremiumLimits.freeHistory))
                return items.filter { $0.updatedAt > since }.count
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.unreadFeedCount = count
            }
            .store(in: &cancellables)
    }
}
