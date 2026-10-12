//
//  MapFlyRequest.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// Asks the map to fly the camera to a point. A new ``id`` repeats the flight even to the same point.
struct MapFlyRequest: Hashable {

    let id: Int

    let coordinate: GeoCoordinate
}
