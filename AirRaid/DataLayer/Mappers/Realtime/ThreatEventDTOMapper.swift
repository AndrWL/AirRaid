//
//  ThreatEventDTOMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Maps API events to ``Threat``.
///
/// The API adds values without a version bump, so every string enum falls back instead of failing:
/// an unknown `kind` becomes ``ThreatKind/unknown``, an unknown `type` becomes `nil`, an unknown `subtype` leaves
/// the `type`.
nonisolated enum ThreatEventDTOMapper {

    static func map(_ dto: ThreatEventDTO) -> Threat {
        let firstSeenAt = Date(timeIntervalSince1970: TimeInterval(dto.firstSeen))
        return Threat(
            id: dto.id,
            kind: mapKind(dto.kind),
            type: dto.subtype.flatMap(mapType) ?? dto.type.flatMap(mapType),
            count: dto.count,
            level: mapLevel(dto.level),
            confidence: dto.confidence,
            sourceCount: dto.sources,
            position: dto.position.map(mapPlace),
            target: dto.target.map(mapPlace),
            trail: (dto.trail ?? []).compactMap(mapTrackPoint),
            area: ThreatArea(
                name: dto.area.name,
                regionID: dto.area.code,
                center: GeoCoordinate(latitude: dto.area.lat, longitude: dto.area.lon)
            ),
            positionQuality: mapPositionQuality(dto.positionQuality, hasPosition: dto.position != nil),
            accuracyKm: dto.accuracyKm ?? 0,
            heading: dto.headingDeg,
            approachBearing: dto.fromDeg,
            speedKmh: max(dto.speedKmh ?? 0, 0),
            speedSource: dto.speedSource == Constants.measuredSpeedSource ? .measured : .typical,
            movedAt: dto.movedAt.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? firstSeenAt,
            firstSeenAt: firstSeenAt,
            updatedAt: Date(timeIntervalSince1970: TimeInterval(dto.updated)),
            expiresAt: Date(timeIntervalSince1970: TimeInterval(dto.expires)),
            summary: dto.summary
        )
    }
}

// MARK: - Private methods

nonisolated private extension ThreatEventDTOMapper {

    static func mapKind(_ value: String) -> ThreatKind {
        switch value {
        case "drone": return .drone
        case "fpv": return .fpv
        case "kab": return .guidedAerialBomb
        case "missile": return .missile
        case "ballistic": return .ballisticMissile
        case "aviation": return .aviation
        default: return .unknown
        }
    }

    static func mapType(_ value: String) -> ThreatType? {
        Constants.types[value]
    }

    /// An unknown level counts as ``ThreatLevel/low``: never show an unrecognized report as more certain than it is.
    static func mapLevel(_ value: String) -> ThreatLevel {
        switch value {
        case "high": return .high
        case "medium": return .medium
        default: return .low
        }
    }

    /// Older servers do not send `position_quality`; infer it from whether a position is present.
    static func mapPositionQuality(
        _ value: String?,
        hasPosition: Bool
    ) -> ThreatPositionQuality {
        switch value {
        case "confirmed": return .confirmed
        case "approx": return .approximate
        case "target_only": return .targetOnly
        case "area": return .area
        default: return hasPosition ? .approximate : .area
        }
    }

    static func mapPlace(_ dto: ThreatPlaceDTO) -> ThreatPlace {
        ThreatPlace(name: dto.name, coordinate: GeoCoordinate(latitude: dto.lat, longitude: dto.lon))
    }

    /// Drops a malformed `[lat, lon, unix]` point instead of the whole event.
    static func mapTrackPoint(_ values: [Double]) -> ThreatTrackPoint? {
        guard values.count >= 3 else { return nil }
        return ThreatTrackPoint(
            coordinate: GeoCoordinate(latitude: values[0], longitude: values[1]),
            time: Date(timeIntervalSince1970: values[2])
        )
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let measuredSpeedSource = "track"
    static let types: [String: ThreatType] = [
        "shahed": .shahed,
        "jet_uav": .jetDrone,
        "recon_uav": .reconDrone,
        "molniya": .molniya,
        "uav": .drone,
        "fpv": .fpv,
        "kab": .guidedAerialBomb,
        "cruise_missile": .cruiseMissile,
        "high_speed_target": .highSpeedTarget,
        "missile": .missile,
        "ballistic": .ballisticMissile,
        "aviation": .aviation
    ]
}
