//
//  PlaceEditorCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The coordinator view for a saved place's screen, pushed on the Settings stack.
struct PlaceEditorCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: PlaceEditorViewModel<PlaceEditorRouter>

    init(
        appContainer: DIAppContaining,
        placeID: SavedPlace.ID
    ) {
        let router = PlaceEditorRouter(
            stackRouter: appContainer.routers.settingsStackRouter,
            tabBarRouter: appContainer.routers.tabBarRouter
        )
        let viewModel = PlaceEditorViewModel(
            placeID: placeID,
            router: router,
            placeSettingsRepository: appContainer.repositories.placeSettingsRepository,
            entitlementService: appContainer.services.entitlementService,
            regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository
        )
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        PlaceEditorView(viewModel: viewModel)
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return NavigationStack {
        PlaceEditorCoordinatorView(appContainer: container, placeID: UUID())
    }
}
