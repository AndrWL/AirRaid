//
//  ThreatDetailsCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import SwiftUI

/// The coordinator view for the threat details sheet.
///
/// A leaf with no navigation of its own, so it has no router: closing is the presenting sheet's dismissal,
/// which also clears the Map router's `activeSheet` through the `.sheet(item:)` binding.
struct ThreatDetailsCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: ThreatDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        appContainer: DIAppContaining,
        threatID: String
    ) {
        let viewModel = ThreatDetailsViewModel(
            threatID: threatID,
            airSituationRepository: appContainer.repositories.airSituationRepository,
            userLocationService: appContainer.services.userLocationService,
            placeSettingsRepository: appContainer.repositories.placeSettingsRepository
        )
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ThreatDetailsView(viewModel: viewModel) {
            dismiss()
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return ThreatDetailsCoordinatorView(appContainer: container, threatID: "shahed-1")
}
