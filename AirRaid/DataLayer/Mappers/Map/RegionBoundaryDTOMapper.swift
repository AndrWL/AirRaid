//
//  RegionBoundaryDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Maps GeoJSON region features to domain ``RegionBoundary`` values.
nonisolated enum RegionBoundaryDTOMapper {

    /// Maps one feature.
    ///
    /// - Throws: ``RegionBoundaryMappingError`` if a position has fewer than two numbers or a polygon has no rings.
    static func map(_ feature: RegionBoundaryFeatureDTO) throws -> RegionBoundary {
        RegionBoundary(
            id: feature.properties.shapeISO,
            name: Constants.ukrainianNames[feature.properties.shapeISO] ?? feature.properties.shapeName,
            polygons: try GeoPolygonDTOMapper.map(feature.geometry, ownerID: feature.properties.shapeISO)
        )
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    /// The source names regions in transliteration («Vinnytska»); the app shows them in Ukrainian.
    static let ukrainianNames: [String: String] = [
        "UA-05": "Вінницька область",
        "UA-07": "Волинська область",
        "UA-09": "Луганська область",
        "UA-12": "Дніпропетровська область",
        "UA-14": "Донецька область",
        "UA-18": "Житомирська область",
        "UA-21": "Закарпатська область",
        "UA-23": "Запорізька область",
        "UA-26": "Івано-Франківська область",
        "UA-30": "Київ",
        "UA-32": "Київська область",
        "UA-35": "Кіровоградська область",
        "UA-40": "Севастополь",
        "UA-43": "Автономна Республіка Крим",
        "UA-46": "Львівська область",
        "UA-48": "Миколаївська область",
        "UA-51": "Одеська область",
        "UA-53": "Полтавська область",
        "UA-56": "Рівненська область",
        "UA-59": "Сумська область",
        "UA-61": "Тернопільська область",
        "UA-63": "Харківська область",
        "UA-65": "Херсонська область",
        "UA-68": "Хмельницька область",
        "UA-71": "Черкаська область",
        "UA-74": "Чернігівська область",
        "UA-77": "Чернівецька область"
    ]
}
