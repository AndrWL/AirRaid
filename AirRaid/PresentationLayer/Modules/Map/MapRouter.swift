//
//  MapRouter.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import Foundation

/// The router responsible for managing the navigation state of the Map flow.
@Observable
final class MapRouter: BaseRouter {

    var activeSheet: MapSheetRoute?

    @ObservationIgnored
    private let intentChannel: MapIntentChannel

    init(
        stackRouter: StackRouting,
        intentChannel: MapIntentChannel
    ) {
        self.intentChannel = intentChannel
        super.init(stackRouter: stackRouter)
    }
}

// MARK: - MapRouterProtocol

extension MapRouter: MapRouterProtocol {

    var intentPublisher: AnyPublisher<MapIntent, Never> {
        intentChannel.intentPublisher
    }
}
