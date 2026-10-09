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
            districts: viewModel.districts,
            cities: viewModel.cities,
            alertCoverage: viewModel.alertCoverage,
            threats: viewModel.threats,
            selectedThreatID: viewModel.selectedThreatID,
            onSelectThreat: viewModel.didSelectThreat
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
                districtBoundaryRepository: DistrictBoundaryRepository(),
                cityRepository: CityRepository(),
                airSituationRepository: DemoAirSituationRepository(),
                styleURL: styleURL
            )
        )
    }
}
