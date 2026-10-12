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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            selection: viewModel.selection,
            onSelect: viewModel.didSelect
        )
        // Edge to edge: the tab bar floats at the top on iPad and at the bottom on iPhone.
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            if let notice = viewModel.connectionNotice {
                MapConnectionBanner(notice: notice)
                    .padding(.top, Spacing.small)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(Motion.resolved(Motion.bouncy, reduceMotion: reduceMotion), value: viewModel.connectionNotice)
        .sensoryFeedback(.selection, trigger: viewModel.selection) { _, newValue in newValue != nil }
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
