//
//  RegionDetailsCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The coordinator view for the region sheet.
///
/// A leaf with no navigation of its own, so it has no router: closing is the presenting sheet's dismissal,
/// which also clears the Map router's `activeSheet` through the `.sheet(item:)` binding.
struct RegionDetailsCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: RegionDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        appContainer: DIAppContaining,
        regionID: String
    ) {
        let viewModel = RegionDetailsViewModel(
            regionID: regionID,
            airSituationRepository: appContainer.repositories.airSituationRepository,
            regionBoundaryRepository: appContainer.repositories.regionBoundaryRepository,
            favoriteRegionsRepository: appContainer.repositories.favoriteRegionsRepository
        )
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        RegionDetailsView(viewModel: viewModel) {
            dismiss()
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return RegionDetailsCoordinatorView(appContainer: container, regionID: "UA-53")
}
