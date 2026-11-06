//
//  StatusPlaceKind+Display.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit

/// The same wording as the app's `WatchedPlaceKind`.
extension StatusPlaceKind {

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .currentLocation: return "location.fill"
        }
    }

    /// "May reach home", "may reach you" — over the forecast arrival time.
    var arrivalLabel: String {
        switch self {
        case .home: return "може бути біля дому"
        case .currentLocation: return "може бути у вас"
        }
    }

    /// "Near home", "near you".
    var nearText: String {
        switch self {
        case .home: return "біля дому"
        case .currentLocation: return "біля вас"
        }
    }
}
