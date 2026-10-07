//
//  RegionGeometryDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// A GeoJSON geometry limited to the types region outlines use.
///
/// Positions are `[longitude, latitude]`, as GeoJSON defines them.
nonisolated enum RegionGeometryDTO: Sendable {

    /// Rings of positions; the first ring is the exterior, the rest are holes.
    case polygon([[[Double]]])

    /// Several polygons.
    case multiPolygon([[[[Double]]]])
}

// MARK: - Decodable

nonisolated extension RegionGeometryDTO: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case Constants.polygon:
            self = .polygon(try container.decode([[[Double]]].self, forKey: .coordinates))
        case Constants.multiPolygon:
            self = .multiPolygon(try container.decode([[[[Double]]]].self, forKey: .coordinates))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unsupported geometry type: \(type)"
            )
        }
    }
}

// MARK: - CodingKeys

nonisolated private extension RegionGeometryDTO {

    enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let polygon = "Polygon"
    static let multiPolygon = "MultiPolygon"
}
