//
//  MapFactory.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import SwiftUI

/// A concrete factory responsible for assembling views presented from the Map tab.
@MainActor
struct MapFactory {

    private let appContainer: DIAppContaining

    init(
        appContainer: DIAppContaining
    ) {
        self.appContainer = appContainer
    }
}

// MARK: - MapFactoryProtocol

extension MapFactory: MapFactoryProtocol {

    @ViewBuilder
    func sheet(for route: MapSheetRoute, actions: MapSheetActions) -> some View {
        switch route {
        case .threatDetails(let id):
            ThreatDetailsCoordinatorView(appContainer: appContainer, threatID: id)
        case .regionDetails(let id):
            RegionDetailsCoordinatorView(appContainer: appContainer, regionID: id)
        case .homeDetails:
            HomeDetailsCoordinatorView(appContainer: appContainer, actions: actions)
        case .places:
            PlacesCoordinatorView(appContainer: appContainer, onPickHomeOnMap: actions.pickHomeOnMap)
        }
    }
}
