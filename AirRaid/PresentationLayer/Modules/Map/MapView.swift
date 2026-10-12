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
        // Edge to edge: the tab bar floats at the top on iPad and at the bottom on iPhone.
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            if let notice = viewModel.connectionNotice {
                MapConnectionBanner(notice: notice)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.connectionNotice)
        .task { await viewModel.onAppear() }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return Group {
        if let styleURL = URL(string: AppEnvironment.mapStyleURLString) {
            MapView(
                viewModel: MapViewModel(
                    router: MapRouter(stackRouter: StackRouter()),
                    regionBoundaryRepository: RegionBoundaryRepository(),
                    districtBoundaryRepository: DistrictBoundaryRepository(),
                    cityRepository: CityRepository(),
                    airSituationRepository: DemoAirSituationRepository(),
                    realtimeService: container.services.realtimeService,
                    styleURL: styleURL
                )
            )
        }
    }
}
