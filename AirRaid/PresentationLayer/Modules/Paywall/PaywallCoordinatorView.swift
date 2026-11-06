//
//  PaywallCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The coordinator view for the AirRaid Plus sheet, presented from the feed and the settings.
struct PaywallCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss

    init(appContainer: DIAppContaining) {
        let viewModel = PaywallViewModel(
            entitlementService: appContainer.services.entitlementService,
            productIDs: AppEnvironment.plusProductIDs
        )
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        PaywallView(viewModel: viewModel) {
            dismiss()
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return PaywallCoordinatorView(appContainer: container)
}
