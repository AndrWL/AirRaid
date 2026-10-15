//
//  VoiceSettingsRouter.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// The router of the voice settings screen: pushed on the Settings stack, presents its own paywall.
@Observable
final class VoiceSettingsRouter: BaseRouter {

    var activeSheet: VoiceSettingsSheetRoute?
}

// MARK: - VoiceSettingsRouterProtocol

extension VoiceSettingsRouter: @MainActor VoiceSettingsRouterProtocol { }
