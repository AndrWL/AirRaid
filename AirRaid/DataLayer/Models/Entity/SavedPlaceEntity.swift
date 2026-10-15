//
//  SavedPlaceEntity.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

/// A ``SavedPlace`` as it is kept in `UserDefaults`. The kind is stored by name, so an unknown one drops that place
/// rather than the list.
nonisolated struct SavedPlaceEntity: Codable, Sendable {
    let id: String
    let kind: String
    let name: String?
    let latitude: Double
    let longitude: Double
    let radiusKm: Double
    let locality: String?
    let street: String?
}
