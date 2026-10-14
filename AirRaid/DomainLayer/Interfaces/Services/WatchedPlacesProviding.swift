//
//  WatchedPlacesProviding.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine

/// The places threats are watched around right now: the current location, the home, and the custom places while
/// AirRaid Плюс is active. The one place that decides it, so the map, the feed and the voice never disagree.
protocol WatchedPlacesProviding {

    /// Emits on subscription and after every change of the location, the places or Плюс.
    var placesPublisher: AnyPublisher<[WatchedPlace], Never> { get }
}
