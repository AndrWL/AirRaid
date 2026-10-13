//
//  PlaceAddressResolving.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// Names the place at a point.
protocol PlaceAddressResolving {

    /// The address at the point, or `nil` when it cannot be found or the lookup fails.
    func address(at coordinate: GeoCoordinate) async -> PlaceAddress?
}
