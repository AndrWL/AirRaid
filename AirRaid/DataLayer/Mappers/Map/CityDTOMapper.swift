//
//  CityDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Maps ``CityDTO`` values to domain ``City`` values.
nonisolated enum CityDTOMapper {

    static func map(_ dto: CityDTO) -> City {
        City(
            name: dto.name,
            coordinate: GeoCoordinate(latitude: dto.latitude, longitude: dto.longitude)
        )
    }
}
