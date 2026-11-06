//
//  SettingsPlaceContent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// A saved place as the settings show it: its name, address and radius, and whether it is watched now.
struct SettingsPlaceContent: Hashable, Identifiable {

    let id: SavedPlace.ID

    let kind: WatchedPlaceKind

    /// "Home", or a custom place by its name or locality.
    let title: String

    /// The street and house number; `nil` until the geocoder names it, or off a named street.
    let street: String?

    /// The locality and the oblast; `nil` until either is known.
    let placeLine: String?

    let radiusKm: Double

    /// A custom place kept while Plus is off: saved, but not watched.
    let isPaused: Bool

    init(
        place: SavedPlace,
        regionName: String?,
        isPlusActive: Bool
    ) {
        id = place.id
        kind = place.watchedKind
        title = place.title
        street = place.address?.street
        // A place named by its locality does not repeat it underneath.
        // Nor the city that is its own region: "Kyiv", not "Kyiv · Kyiv".
        let locality = place.address?.locality == title ? nil : place.address?.locality
        var parts = [locality, regionName].compactMap { $0 }
        if parts.count == 2, parts[0] == parts[1] {
            parts.removeLast()
        }
        placeLine = parts.isEmpty ? nil : parts.joined(separator: " · ")
        radiusKm = place.radiusKm
        isPaused = place.kind == .custom && !isPlusActive
    }
}
