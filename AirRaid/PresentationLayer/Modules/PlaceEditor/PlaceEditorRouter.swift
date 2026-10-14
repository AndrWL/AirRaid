//
//  PlaceEditorRouter.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// The router of a saved place's screen: pushed on the Settings stack, hands moving the place over to the map.
@Observable
final class PlaceEditorRouter: BaseRouter {

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

// MARK: - PlaceEditorRouterProtocol

extension PlaceEditorRouter: @MainActor PlaceEditorRouterProtocol {

    func showPlacePickerOnMap(_ pick: PlacePick) {
        tabBarRouter.showPlacePickerOnMap(pick)
    }

    func close() {
        stackRouter.pop(animated: true)
    }
}
