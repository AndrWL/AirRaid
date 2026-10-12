//
//  MapSheetActions.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// What a sheet presented from the Map tab can ask the map to do. Routes carry only identifiers, so the map's
/// coordinator hands these to the factory alongside the route.
struct MapSheetActions {

    /// Closes the sheet and lets the user place the home under a pin at the centre of the map.
    let pickHomeOnMap: () -> Void
}
