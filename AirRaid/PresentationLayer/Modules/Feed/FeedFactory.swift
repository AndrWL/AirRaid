//
//  FeedFactory.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// A concrete factory responsible for assembling the sheets of the Feed flow.
@MainActor
struct FeedFactory {

    private let appContainer: DIAppContaining

    init(appContainer: DIAppContaining) {
        self.appContainer = appContainer
    }
}

// MARK: - FeedFactoryProtocol

extension FeedFactory: FeedFactoryProtocol {

    @ViewBuilder
    func sheet(for route: FeedSheetRoute) -> some View {
        switch route {
        case .paywall:
            PaywallCoordinatorView(appContainer: appContainer)
        case .nightReport:
            NightReportCoordinatorView(appContainer: appContainer)
        }
    }
}
