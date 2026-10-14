//
//  SettingsRouter.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// The router responsible for managing the navigation state of the Settings flow.
@Observable
final class SettingsRouter: BaseRouter {

    var activeSheet: SettingsSheetRoute?

    /// Moves the user to another tab: places are picked on the map.
    @ObservationIgnored
    private let tabBarRouter: TabBarRouterProtocol

    init(
        stackRouter: StackRouting,
        tabBarRouter: TabBarRouterProtocol
    ) {
        self.tabBarRouter = tabBarRouter
        super.init(stackRouter: stackRouter)
    }
}

// MARK: - SettingsRouterProtocol

extension SettingsRouter: @MainActor SettingsRouterProtocol {

    func showPlacePickerOnMap(_ pick: PlacePick) {
        tabBarRouter.showPlacePickerOnMap(pick)
    }

    func showPlace(_ id: SavedPlace.ID) {
        stackRouter.push(SettingsRoute.place(id: id), animated: true)
    }

    func showVoiceSettings() {
        stackRouter.push(SettingsRoute.voice, animated: true)
    }
}
