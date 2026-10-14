//
//  FeedCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The coordinator view for the Feed tab. Owns the tab's navigation stack and its sheets.
struct FeedCoordinatorView<Factory: FeedFactoryProtocol>: View {

    // MARK: - Variables

    @State private var viewModel: FeedViewModel<FeedRouter>
    @State private var router: FeedRouter

    private let factory: Factory

    init(
        appContainer: DIAppContaining,
        factory: Factory
    ) {
        let router = FeedRouter(
            stackRouter: appContainer.routers.feedStackRouter,
            tabBarRouter: appContainer.routers.tabBarRouter
        )
        let services = appContainer.services
        let repositories = appContainer.repositories
        let viewModel = FeedViewModel(
            router: router,
            dependencies: FeedViewModel.Dependencies(
                feedRepository: repositories.feedRepository,
                airSituationRepository: repositories.airSituationRepository,
                watchedPlacesProvider: services.watchedPlacesProvider,
                watchedRegionsProvider: services.watchedRegionsProvider,
                entitlementService: services.entitlementService,
                voiceAnnouncer: services.feedVoiceAnnouncer,
                homeStatusBroadcaster: services.homeStatusBroadcaster
            )
        )

        self._router = State(wrappedValue: router)
        self._viewModel = State(wrappedValue: viewModel)
        self.factory = factory
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            FeedView(viewModel: viewModel)
        }
        .sheet(item: $router.activeSheet) { route in
            factory.sheet(for: route)
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return FeedCoordinatorView(
        appContainer: container,
        factory: FeedFactory(appContainer: container)
    )
}
