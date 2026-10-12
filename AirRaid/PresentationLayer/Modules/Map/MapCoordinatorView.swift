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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
            realtimeService: appContainer.services.realtimeService,
            favoriteRegionsRepository: appContainer.repositories.favoriteRegionsRepository,
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
                // On iPad a side column, so the details do not cover the map they describe.
                .inspector(isPresented: isInspectorPresented) {
                    if let route = router.activeSheet {
                        sheetContent(for: route)
                            .inspectorColumnWidth(min: 320, ideal: 380, max: 480)
                    }
                }
                // The inspector's container keeps the safe area even when the map ignores it, which leaves
                // a blank band under the status bar and the top tab bar.
                .ignoresSafeArea()
        }
        // On iPhone a sheet: an inspector in compact width also becomes a sheet, but ignores the detents.
        .sheet(item: compactSheet) { route in
            sheetContent(for: route)
                .presentationDetents(route.detents)
                // The map stays usable under the half-height sheet, so another pin can be tapped right away.
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }
}

// MARK: - Private methods

private extension MapCoordinatorView {

    var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    /// `inspector` takes a `Bool`; closing it (the close button) clears the router's sheet.
    var isInspectorPresented: Binding<Bool> {
        Binding(
            get: { isRegularWidth && router.activeSheet != nil },
            set: { isPresented in
                if !isPresented { router.dismissSheet() }
            }
        )
    }

    /// The router's sheet, shown as a sheet only while the width is compact.
    var compactSheet: Binding<MapSheetRoute?> {
        Binding(
            get: { isRegularWidth ? nil : router.activeSheet },
            set: { router.activeSheet = $0 }
        )
    }

    func sheetContent(for route: MapSheetRoute) -> some View {
        factory.sheet(for: route)
            // Tapping another pin swaps the route of the sheet already on screen (see `MapSheetRoute.id`);
            // a new identity rebuilds the module, whose view model would otherwise keep the old threat.
            .id(route)
    }

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
