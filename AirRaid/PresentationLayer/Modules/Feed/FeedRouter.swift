//
//  FeedRouter.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// The router responsible for managing the navigation state of the Feed flow.
@Observable
final class FeedRouter: BaseRouter {

    var activeSheet: FeedSheetRoute?

    /// Moves the user to the map to show a threat there.
    @ObservationIgnored
    private let tabBarRouter: TabBarRouterProtocol

    init(
        stackRouter: StackRouting,
        tabBarRouter: TabBarRouterProtocol
    ) {
        self.tabBarRouter = tabBarRouter
        super.init(stackRouter: stackRouter)
    }
}

// MARK: - FeedRouterProtocol

extension FeedRouter: @MainActor FeedRouterProtocol {

    func showThreatOnMap(id: String) {
        tabBarRouter.showThreatOnMap(id: id)
    }
}
