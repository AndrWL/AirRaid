//
//  PlacePick.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// What the map's centre pin is placing: the home, a new place, or a saved place being moved.
enum PlacePick: Hashable {

    /// Sets the home, or moves it when there is one.
    case home

    /// Adds a custom place; the caller has checked AirRaid Plus and the limit.
    case newPlace

    /// Moves the saved place with this id.
    case move(id: SavedPlace.ID)
}
