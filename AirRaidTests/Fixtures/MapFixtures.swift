//
//  MapFixtures.swift
//  AirRaidTests
//

import Foundation
@testable import AirRaid

/// Shared places for the map tests: real coordinates, so distances read the way they would on the map, and square
/// outlines in degrees, so whether a point is inside one is obvious.
enum MapFixtures {

    /// Біла Церква, where `Threat.stub` puts a threat by default.
    static let bilaTserkva = GeoCoordinate(latitude: 49.8, longitude: 30.1)

    /// Київ.
    static let kyiv = GeoCoordinate(latitude: 50.45, longitude: 30.52)

    /// A square outline of `halfSize` degrees either side of `center`.
    static func square(
        center: GeoCoordinate,
        halfSize: Double
    ) -> GeoPolygon {
        rectangle(
            south: center.latitude - halfSize,
            west: center.longitude - halfSize,
            north: center.latitude + halfSize,
            east: center.longitude + halfSize
        )
    }

    /// A rectangular outline between the given latitudes and longitudes.
    static func rectangle(
        south: Double,
        west: Double,
        north: Double,
        east: Double,
        holes: [[GeoCoordinate]] = []
    ) -> GeoPolygon {
        GeoPolygon(
            exterior: [
                GeoCoordinate(latitude: south, longitude: west),
                GeoCoordinate(latitude: south, longitude: east),
                GeoCoordinate(latitude: north, longitude: east),
                GeoCoordinate(latitude: north, longitude: west)
            ],
            holes: holes
        )
    }
}

// MARK: - Threat

extension Threat {

    static func stub(
        id: String = "t1",
        kind: ThreatKind = .drone,
        type: ThreatType? = .shahed,
        count: Int? = nil,
        level: ThreatLevel = .medium,
        sourceCount: Int = 2,
        regionID: String = "UA-32",
        regionName: String = "Київська область",
        positionName: String? = "Біла Церква",
        targetName: String? = nil,
        positionCoordinate: GeoCoordinate = MapFixtures.bilaTserkva,
        targetCoordinate: GeoCoordinate = MapFixtures.bilaTserkva,
        areaCenter: GeoCoordinate = MapFixtures.bilaTserkva,
        trail: [GeoCoordinate] = [],
        positionQuality: ThreatPositionQuality = .confirmed,
        accuracyKm: Double = 5,
        heading: Double? = nil,
        speedKmh: Double = 150,
        speedSource: ThreatSpeedSource = .typical,
        firstSeenAt: Date = FeedFixtures.origin,
        updatedAt: Date? = nil,
        movedAt: Date? = nil,
        expiresAt: Date? = nil
    ) -> Threat {
        let updatedAt = updatedAt ?? firstSeenAt
        return Threat(
            id: id,
            kind: kind,
            type: type,
            count: count,
            level: level,
            confidence: 0.7,
            sourceCount: sourceCount,
            position: positionName.map { ThreatPlace(name: $0, coordinate: positionCoordinate) },
            target: targetName.map { ThreatPlace(name: $0, coordinate: targetCoordinate) },
            trail: trail.map { ThreatTrackPoint(coordinate: $0, time: firstSeenAt) },
            area: ThreatArea(name: regionName, regionID: regionID, center: areaCenter),
            positionQuality: positionQuality,
            accuracyKm: accuracyKm,
            heading: heading,
            approachBearing: nil,
            speedKmh: speedKmh,
            speedSource: speedSource,
            movedAt: movedAt ?? updatedAt,
            firstSeenAt: firstSeenAt,
            updatedAt: updatedAt,
            expiresAt: expiresAt ?? updatedAt.addingTimeInterval(1_800),
            summary: nil
        )
    }
}

// MARK: - RegionAlert

extension RegionAlert {

    static func stub(
        id: String = "a1",
        kind: RegionAlertKind = .airRaid,
        level: RegionAlertLevel? = nil,
        scope: RegionAlertScope = .raion,
        name: String = "Бучанський район",
        regionID: String = "UA-32",
        district: DistrictKey? = nil,
        startedAt: Date = FeedFixtures.origin
    ) -> RegionAlert {
        RegionAlert(
            id: id,
            kind: kind,
            level: level,
            scope: scope,
            name: name,
            regionID: regionID,
            district: district,
            startedAt: startedAt
        )
    }
}

// MARK: - Boundaries

extension RegionBoundary {

    static func stub(
        id: String = "UA-32",
        name: String = "Київська область",
        polygons: [GeoPolygon]
    ) -> RegionBoundary {
        RegionBoundary(id: id, name: name, polygons: polygons)
    }
}

extension DistrictBoundary {

    static func stub(
        regionID: String = "UA-32",
        name: String = "Бучанський",
        polygons: [GeoPolygon]
    ) -> DistrictBoundary {
        DistrictBoundary(id: "\(regionID)-\(name)", key: DistrictKey(regionID: regionID, name: name), polygons: polygons)
    }
}

// MARK: - WatchedPlace

extension WatchedPlace {

    static func stub(
        id: String = "home",
        kind: WatchedPlaceKind = .home,
        name: String? = nil,
        coordinate: GeoCoordinate = MapFixtures.bilaTserkva,
        radiusKm: Double = 25,
        address: PlaceAddress? = nil
    ) -> WatchedPlace {
        WatchedPlace(id: id, kind: kind, name: name, coordinate: coordinate, radiusKm: radiusKm, address: address)
    }
}
