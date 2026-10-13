//
//  PlaceAddress.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// A place's address as a reverse geocoder names it, in Ukrainian.
nonisolated struct PlaceAddress: Hashable, Sendable {

    /// «Ірпінь»; `nil` outside any settlement.
    let locality: String?

    /// «вулиця Соборна, 12»; `nil` when the point is not on a named street.
    let street: String?
}
