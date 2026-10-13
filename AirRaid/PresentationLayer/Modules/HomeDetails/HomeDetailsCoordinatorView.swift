//
//  HomeDetailsCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// The coordinator view for the home sheet.
///
/// A leaf with no router: moving the home and opening a threat are the map's, handed over as ``MapSheetActions``.
struct HomeDetailsCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: HomeDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    private let actions: MapSheetActions

    init(
        appContainer: DIAppContaining,
        actions: MapSheetActions
    ) {
        let viewModel = HomeDetailsViewModel(
            placeSettingsRepository: appContainer.repositories.placeSettingsRepository,
            airSituationRepository: appContainer.repositories.airSituationRepository,
            regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository,
            districtBoundaryRepository: appContainer.repositories.districtBoundaryRepository
        )
        self._viewModel = State(wrappedValue: viewModel)
        self.actions = actions
    }

    var body: some View {
        HomeDetailsView(
            viewModel: viewModel,
            onMoveHome: actions.pickHomeOnMap,
            onSelectThreat: actions.showThreat
        ) {
            dismiss()
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return HomeDetailsCoordinatorView(
        appContainer: container,
        actions: MapSheetActions(pickHomeOnMap: {}, showThreat: { _ in })
    )
}
