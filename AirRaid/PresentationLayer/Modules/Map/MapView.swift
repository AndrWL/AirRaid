//
//  MapView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import SwiftUI

/// The primary user interface for the Map tab: a full-screen map of alerts and threats.
struct MapView<ViewModel: MapViewModelProtocol>: View {

    // MARK: - Variables

    private let viewModel: ViewModel

    init(
        viewModel: ViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        AirRaidMapView(
            styleURL: viewModel.styleURL,
            boundaries: viewModel.boundaries,
            cities: viewModel.cities,
            alertedRegionIDs: viewModel.alertedRegionIDs,
            threats: viewModel.threats
        )
        .ignoresSafeArea(edges: .top)
        .task { await viewModel.onAppear() }
    }
}

#Preview {
    if let styleURL = URL(string: AppEnvironment.mapStyleURLString) {
        MapView(
            viewModel: MapViewModel(
                router: MapRouter(stackRouter: StackRouter()),
                regionBoundaryRepository: RegionBoundaryRepository(),
                cityRepository: CityRepository(),
                airSituationRepository: DemoAirSituationRepository(),
                styleURL: styleURL
            )
        )
    }
}
