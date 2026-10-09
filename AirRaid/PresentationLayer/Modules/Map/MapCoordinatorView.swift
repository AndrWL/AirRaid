//
//  MapCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import SwiftUI

/// The coordinator view for the Map tab. Owns the tab's navigation stack and the threat details sheet.
struct MapCoordinatorView<Factory: MapFactoryProtocol>: View {

    // MARK: - Variables

    @State private var viewModel: MapViewModel<MapRouter>
    @State private var router: MapRouter

    private let factory: Factory

    init(
        appContainer: DIAppContaining,
        factory: Factory
    ) {
        let router = MapRouter(stackRouter: appContainer.routers.mapStackRouter)
        let viewModel = MapViewModel(
            router: router,
            regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository,
            districtBoundaryRepository: appContainer.repositories.districtBoundaryRepository,
            cityRepository: appContainer.repositories.cityRepository,
            airSituationRepository: appContainer.repositories.airSituationRepository,
            styleURL: Self.makeStyleURL()
        )

        self._router = State(wrappedValue: router)
        self._viewModel = State(wrappedValue: viewModel)
        self.factory = factory
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            MapView(viewModel: viewModel)
                .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $router.activeSheet) { route in
            factory.sheet(for: route)
                // Tapping another pin swaps the route of the sheet already on screen (see `MapSheetRoute.id`);
                // a new identity rebuilds the module, whose view model would otherwise keep the old threat.
                .id(route)
                .presentationDetents(route.detents)
                // The map stays usable under the half-height sheet, so another pin can be tapped right away.
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }
}

// MARK: - Private methods

private extension MapCoordinatorView {

    static func makeStyleURL() -> URL {
        guard let url = URL(string: AppEnvironment.mapStyleURLString) else {
            fatalError("[MapCoordinatorView] Invalid map style URL: \(AppEnvironment.mapStyleURLString)")
        }
        return url
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return MapCoordinatorView(
        appContainer: container,
        factory: MapFactory(appContainer: container)
    )
}
