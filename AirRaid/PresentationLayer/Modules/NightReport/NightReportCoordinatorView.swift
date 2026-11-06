//
//  NightReportCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The coordinator view for the night report sheet. AirRaid Plus: the feed opens the paywall without it.
struct NightReportCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: NightReportViewModel
    @Environment(\.dismiss) private var dismiss

    init(appContainer: DIAppContaining) {
        let viewModel = NightReportViewModel(
            feedRepository: appContainer.repositories.feedRepository,
            watchedRegionsProvider: appContainer.services.watchedRegionsProvider,
            speechService: appContainer.services.speechService,
            voiceSettingsService: appContainer.services.voiceSettingsService
        )
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NightReportView(viewModel: viewModel) {
            dismiss()
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return NightReportCoordinatorView(appContainer: container)
}
