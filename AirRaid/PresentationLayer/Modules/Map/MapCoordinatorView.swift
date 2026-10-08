//
//  MapCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import SwiftUI

/// The coordinator view for the Map tab. Owns the tab's navigation stack.
struct MapCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: MapViewModel
    @State private var router: MapRouter

    init(
        appContainer: DIAppContaining
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
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            MapView(viewModel: viewModel)
                .toolbar(.hidden, for: .navigationBar)
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

    return MapCoordinatorView(appContainer: container)
}
