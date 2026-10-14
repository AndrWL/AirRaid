//
//  SettingsHomeContent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// The home as the settings show it: its address and radius.
struct SettingsHomeContent: Hashable {

    /// «вулиця Соборна, 12»; `nil` until the geocoder names it, or off a named street.
    let street: String?

    /// «Ірпінь · Київська область»; `nil` until either is known.
    let placeLine: String?

    let radiusKm: Double

    init(
        home: HomePlace,
        regionName: String?
    ) {
        street = home.address?.street
        let parts = [home.address?.locality, regionName].compactMap { $0 }
        placeLine = parts.isEmpty ? nil : parts.joined(separator: " · ")
        radiusKm = home.radiusKm
    }
}
