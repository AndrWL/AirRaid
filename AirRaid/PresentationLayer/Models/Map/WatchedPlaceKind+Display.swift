//
//  WatchedPlaceKind+Display.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

extension WatchedPlaceKind {

    /// «Моя геолокація», «Дім».
    var title: String {
        switch self {
        case .currentLocation: return "Моя геолокація"
        case .home: return "Дім"
        }
    }

    /// «від вас», «від дому» — after a distance.
    var fromText: String {
        switch self {
        case .currentLocation: return "від вас"
        case .home: return "від дому"
        }
    }

    /// «Може бути у вас», «Може бути біля дому» — before a time of arrival.
    var arrivalLabel: String {
        switch self {
        case .currentLocation: return "Може бути у вас"
        case .home: return "Може бути біля дому"
        }
    }

    var systemImage: String {
        switch self {
        case .currentLocation: return "location.fill"
        case .home: return "house.fill"
        }
    }

    /// The place's colour on the map: its circle, and for the home its pin.
    var tint: Color {
        switch self {
        case .currentLocation: return .mapPlace
        case .home: return .mapHome
        }
    }
}
