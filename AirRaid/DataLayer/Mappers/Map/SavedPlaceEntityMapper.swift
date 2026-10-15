//
//  SavedPlaceEntityMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Converts saved places to and from their stored form.
nonisolated enum SavedPlaceEntityMapper {

    static func map(_ place: SavedPlace) -> SavedPlaceEntity {
        SavedPlaceEntity(
            id: place.id.uuidString,
            kind: place.kind.rawValue,
            name: place.name,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            radiusKm: place.radiusKm,
            locality: place.address?.locality,
            street: place.address?.street
        )
    }

    /// `nil` for a place this build cannot read.
    static func map(_ entity: SavedPlaceEntity) -> SavedPlace? {
        guard let id = UUID(uuidString: entity.id), let kind = SavedPlaceKind(rawValue: entity.kind) else { return nil }
        let hasAddress = entity.locality != nil || entity.street != nil
        return SavedPlace(
            id: id,
            kind: kind,
            name: entity.name,
            coordinate: GeoCoordinate(latitude: entity.latitude, longitude: entity.longitude),
            radiusKm: entity.radiusKm,
            address: hasAddress ? PlaceAddress(locality: entity.locality, street: entity.street) : nil
        )
    }
}
