//
//  MapIntentChannel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Combine

/// What another tab can ask the Map tab to do. The map's state lives in its view model, not in a route, so these
/// travel through ``MapIntentChannel`` instead of a navigation path.
enum MapIntent {

    /// Let the user place or move the home under a pin at the centre of the map.
    case pickHome
}

/// Carries ``MapIntent``s from ``TabBarRouter`` to the Map tab's router.
///
/// The Map tab is the first one shown, so its view model is alive and listening whenever another tab sends.
final class MapIntentChannel {

    // MARK: - Variables

    private let subject = PassthroughSubject<MapIntent, Never>()

    var intentPublisher: AnyPublisher<MapIntent, Never> {
        subject.eraseToAnyPublisher()
    }

    func send(_ intent: MapIntent) {
        subject.send(intent)
    }
}
