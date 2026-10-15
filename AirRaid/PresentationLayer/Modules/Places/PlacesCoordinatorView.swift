//
//  PlacesCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The coordinator view for the places sheet.
///
/// A leaf with no navigation of its own, so it has no router: closing is the presenting sheet's dismissal,
/// which also clears the Map router's `activeSheet` through the `.sheet(item:)` binding.
struct PlacesCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: PlacesViewModel
    @Environment(\.dismiss) private var dismiss

    private let onPickHomeOnMap: () -> Void

    init(
        appContainer: DIAppContaining,
        onPickHomeOnMap: @escaping () -> Void
    ) {
        self.onPickHomeOnMap = onPickHomeOnMap
        let viewModel = PlacesViewModel(
            placeSettingsRepository: appContainer.repositories.placeSettingsRepository,
            userLocationService: appContainer.services.userLocationService,
            regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository,
            entitlementService: appContainer.services.entitlementService
        )
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        PlacesView(viewModel: viewModel, onPickHomeOnMap: onPickHomeOnMap) {
            dismiss()
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return PlacesCoordinatorView(appContainer: container, onPickHomeOnMap: {})
}
