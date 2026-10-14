//
//  SettingsCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// The coordinator view for the Settings tab. Owns the tab's navigation stack.
struct SettingsCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: SettingsViewModel
    @State private var router: SettingsRouter

    init(appContainer: DIAppContaining) {
        let router = SettingsRouter(
            stackRouter: appContainer.routers.settingsStackRouter,
            tabBarRouter: appContainer.routers.tabBarRouter
        )
        let viewModel = SettingsViewModel(
            router: router,
            placeSettingsRepository: appContainer.repositories.placeSettingsRepository,
            regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository,
            alertSoundService: appContainer.services.alertSoundService,
            liveActivitySettingsService: appContainer.services.liveActivitySettingsService,
            notificationPermissionService: appContainer.services.notificationPermissionService,
            versionInfo: .current(),
            feedbackEmail: AppEnvironment.feedbackEmail
        )

        self._router = State(wrappedValue: router)
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            SettingsView(viewModel: viewModel)
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return SettingsCoordinatorView(appContainer: container)
}
