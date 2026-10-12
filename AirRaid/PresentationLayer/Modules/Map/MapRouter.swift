//
//  MapRouter.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// The router responsible for managing the navigation state of the Map flow.
@Observable
final class MapRouter: BaseRouter {

    var activeSheet: MapSheetRoute?
}

// MARK: - MapRouterProtocol

extension MapRouter: MapRouterProtocol {

}
