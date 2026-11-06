//
//  RegionAlertStatus.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

/// A region's air raid state, as the map fills it.
enum RegionAlertStatus: Hashable {

    /// The whole region is under an air raid alert.
    case whole(RegionAlertLevel)

    /// Only some raions or hromadas are; the level is the highest among them.
    case partial(RegionAlertLevel)

    /// No air raid alert anywhere in the region.
    case clear

    init(
        coverage: AirRaidCoverage,
        regionID: String
    ) {
        if let level = coverage.regions[regionID] {
            self = .whole(level)
            return
        }
        let level = coverage.districts.filter { $0.key.regionID == regionID }.map(\.value.level).max()
        self = level.map(Self.partial) ?? .clear
    }

    /// An air raid alert, an alert in part of the oblast, or no alert.
    var title: String {
        switch self {
        case .whole: return "Повітряна тривога"
        case .partial: return "Тривога в частині області"
        case .clear: return "Тривоги немає"
        }
    }

    var level: RegionAlertLevel? {
        switch self {
        case .whole(let level), .partial(let level): return level
        case .clear: return nil
        }
    }
}
