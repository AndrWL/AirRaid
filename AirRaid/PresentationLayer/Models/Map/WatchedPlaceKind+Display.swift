//
//  WatchedPlaceKind+Display.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

extension WatchedPlaceKind {

    /// "My location", "Home", or "Place" for a custom place without a name yet.
    var title: String {
        switch self {
        case .currentLocation: return "Моя геолокація"
        case .home: return "Дім"
        case .custom: return "Місце"
        }
    }

    var systemImage: String {
        switch self {
        case .currentLocation: return "location.fill"
        case .home: return "house.fill"
        case .custom: return "mappin"
        }
    }

    /// The place's colour on the map: its circle, and for a saved place its pin.
    var tint: Color {
        switch self {
        case .currentLocation: return .mapPlace
        case .home: return .mapHome
        case .custom: return .mapSavedPlace
        }
    }
}

extension WatchedPlace {

    /// "My location", "Home", or the custom place's name.
    var title: String {
        name ?? kind.title
    }

    /// "From you", "from home", or from the custom place by its name — after a distance.
    var fromText: String {
        switch kind {
        case .currentLocation: return "від вас"
        case .home: return "від дому"
        case .custom: return "від «\(title)»"
        }
    }

    /// "Near you", "near home", or near the custom place by its name.
    var nearText: String {
        switch kind {
        case .currentLocation: return "поруч із вами"
        case .home: return "біля дому"
        case .custom: return "біля «\(title)»"
        }
    }

    /// "May reach you", "may reach home" — before a time of arrival.
    var arrivalLabel: String {
        switch kind {
        case .currentLocation: return "Може бути у вас"
        case .home, .custom: return "Може бути \(nearText)"
        }
    }
}

extension SavedPlace {

    /// "Home", or a custom place by its name, else by its locality until it has a name.
    var title: String {
        WatchedPlace(self).title
    }

    var watchedKind: WatchedPlaceKind {
        kind == .home ? .home : .custom
    }
}
