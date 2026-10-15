//
//  PlaceDetailsCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// The coordinator view for a saved place's sheet.
///
/// A leaf with no router: moving the place and opening a threat are the map's, handed over as ``MapSheetActions``.
struct PlaceDetailsCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: PlaceDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    private let actions: MapSheetActions

    init(
        appContainer: DIAppContaining,
        placeID: SavedPlace.ID,
        actions: MapSheetActions
    ) {
        let viewModel = PlaceDetailsViewModel(
            placeID: placeID,
            placeSettingsRepository: appContainer.repositories.placeSettingsRepository,
            airSituationRepository: appContainer.repositories.airSituationRepository,
            regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository,
            districtBoundaryRepository: appContainer.repositories.districtBoundaryRepository
        )
        self._viewModel = State(wrappedValue: viewModel)
        self.actions = actions
    }

    var body: some View {
        PlaceDetailsView(
            viewModel: viewModel,
            onMove: { actions.pickPlaceOnMap(viewModel.pick) },
            onSelectThreat: actions.showThreat
        ) {
            dismiss()
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return PlaceDetailsCoordinatorView(
        appContainer: container,
        placeID: UUID(),
        actions: MapSheetActions(pickPlaceOnMap: { _ in }, showThreat: { _ in })
    )
}
