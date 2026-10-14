//
//  SettingsFactory.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// A concrete factory responsible for assembling the screens and sheets of the Settings flow.
@MainActor
struct SettingsFactory {

    private let appContainer: DIAppContaining

    init(appContainer: DIAppContaining) {
        self.appContainer = appContainer
    }
}

// MARK: - SettingsFactoryProtocol

extension SettingsFactory: SettingsFactoryProtocol {

    @ViewBuilder
    func navigationDestination(for route: SettingsRoute) -> some View {
        switch route {
        case .voice:
            VoiceSettingsCoordinatorView(appContainer: appContainer)
        }
    }

    @ViewBuilder
    func sheet(for route: SettingsSheetRoute) -> some View {
        switch route {
        case .paywall:
            PaywallCoordinatorView(appContainer: appContainer)
        }
    }
}
