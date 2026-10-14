//
//  VoiceSettingsCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The coordinator view for the voice settings, pushed on the Settings stack: no stack of its own, but its own paywall.
struct VoiceSettingsCoordinatorView: View {

    // MARK: - Variables

    @State private var viewModel: VoiceSettingsViewModel<VoiceSettingsRouter>
    @State private var router: VoiceSettingsRouter

    private let appContainer: DIAppContaining

    init(appContainer: DIAppContaining) {
        let router = VoiceSettingsRouter(stackRouter: appContainer.routers.settingsStackRouter)
        let services = appContainer.services
        let viewModel = VoiceSettingsViewModel(
            router: router,
            voiceSettingsService: services.voiceSettingsService,
            entitlementService: services.entitlementService,
            alertSoundService: services.alertSoundService,
            speechService: services.speechService
        )
        self._router = State(wrappedValue: router)
        self._viewModel = State(wrappedValue: viewModel)
        self.appContainer = appContainer
    }

    var body: some View {
        VoiceSettingsView(viewModel: viewModel)
            .sheet(item: $router.activeSheet) { route in
                switch route {
                case .paywall:
                    PaywallCoordinatorView(appContainer: appContainer)
                }
            }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return NavigationStack {
        VoiceSettingsCoordinatorView(appContainer: container)
    }
}
