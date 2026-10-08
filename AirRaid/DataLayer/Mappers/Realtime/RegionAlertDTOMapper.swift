//
//  RegionAlertDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

import Foundation

/// Maps relayed alerts.in.ua alerts to ``RegionAlert``; unknown strings fall back instead of failing.
nonisolated enum RegionAlertDTOMapper {

    static func map(_ dto: RegionAlertDTO) -> RegionAlert {
        RegionAlert(
            id: dto.uid,
            kind: Constants.kinds[dto.kind] ?? .unknown,
            level: dto.level.flatMap { Constants.levels[$0] },
            scope: Constants.scopes[dto.locationType] ?? .unknown,
            name: dto.name,
            regionID: Constants.cityRegionIDs[dto.name] ?? dto.code,
            district: district(of: dto),
            startedAt: Date(timeIntervalSince1970: TimeInterval(dto.since))
        )
    }
}

// MARK: - Private methods

nonisolated private extension RegionAlertDTOMapper {

    /// The raion a raion or hromada alert falls in, keyed like the bundled raion outlines.
    static func district(of dto: RegionAlertDTO) -> DistrictKey? {
        let raionName: String?
        switch dto.locationType {
        case "raion": raionName = dto.name
        case "hromada": raionName = dto.raion
        default: raionName = nil
        }
        guard let raionName else { return nil }
        let shortName = raionName.replacingOccurrences(of: Constants.raionSuffix, with: "")
        return DistrictKey(regionID: dto.code, name: shortName)
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let kinds: [String: RegionAlertKind] = [
        "air_raid": .airRaid,
        "artillery_shelling": .artilleryShelling,
        "urban_fights": .urbanFights,
        "chemical": .chemical,
        "nuclear": .nuclear
    ]
    static let levels: [String: RegionAlertLevel] = [
        "red": .red,
        "yellow": .yellow
    ]
    static let raionSuffix = " район"
    /// Cities that are regions of their own; the source may file them under the surrounding oblast's code.
    static let cityRegionIDs: [String: String] = [
        "м. Київ": "UA-30",
        "м. Севастополь": "UA-40"
    ]
    static let scopes: [String: RegionAlertScope] = [
        "oblast": .oblast,
        "raion": .raion,
        "hromada": .hromada,
        "city": .city
    ]
}
