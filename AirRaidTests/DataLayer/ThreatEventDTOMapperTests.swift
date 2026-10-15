//
//  ThreatEventDTOMapperTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``ThreatEventDTOMapper``.
///
/// Covers a full event decoded from the API's JSON, every known `kind` and `type`, and the fallbacks the API's
/// unversioned additions rely on: an unknown kind, type, level or position quality, missing optional fields, a
/// negative speed and malformed track points.
@Suite
struct ThreatEventDTOMapperTests {

    // MARK: - map: a full event

    @Test
    func map_whenFullEventDecoded_mapsEveryField() throws {
        let dto = try JSONDecoder().decode(ThreatEventDTO.self, from: Data(Constants.fullEventJSON.utf8))

        let threat = ThreatEventDTOMapper.map(dto)

        #expect(threat == Threat(
            id: "evt-1",
            kind: .drone,
            type: .shahed,
            count: 3,
            level: .high,
            confidence: 0.85,
            sourceCount: 4,
            position: ThreatPlace(name: "Біла Церква", coordinate: GeoCoordinate(latitude: 49.8, longitude: 30.1)),
            target: ThreatPlace(name: "Київ", coordinate: GeoCoordinate(latitude: 50.45, longitude: 30.52)),
            trail: [
                ThreatTrackPoint(
                    coordinate: GeoCoordinate(latitude: 49.5, longitude: 30.0),
                    time: Date(timeIntervalSince1970: 1_791_935_400)
                )
            ],
            area: ThreatArea(
                name: "Київська область",
                regionID: "UA-32",
                center: GeoCoordinate(latitude: 50.05, longitude: 30.77)
            ),
            positionQuality: .confirmed,
            accuracyKm: 3.5,
            heading: 15,
            approachBearing: 190,
            speedKmh: 170,
            speedSource: .measured,
            movedAt: Date(timeIntervalSince1970: 1_791_935_700),
            firstSeenAt: Date(timeIntervalSince1970: 1_791_935_000),
            updatedAt: Date(timeIntervalSince1970: 1_791_935_800),
            expiresAt: Date(timeIntervalSince1970: 1_791_937_600),
            summary: "Шахед ×3 курсом на Київ"
        ))
    }

    // MARK: - map: kind and type

    @Test(arguments: [
        ("drone", ThreatKind.drone),
        ("fpv", .fpv),
        ("kab", .guidedAerialBomb),
        ("missile", .missile),
        ("ballistic", .ballisticMissile),
        ("aviation", .aviation),
        ("hypersonic", .unknown),
        ("", .unknown),
        ("Drone", .unknown)
    ])
    func map_whenKind_mapsOrFallsBackToUnknown(kind: String, expected: ThreatKind) {
        let threat = ThreatEventDTOMapper.map(.stub(kind: kind))

        #expect(threat.kind == expected)
    }

    @Test(arguments: [
        ("shahed", ThreatType?.some(.shahed)),
        ("jet_uav", .jetDrone),
        ("recon_uav", .reconDrone),
        ("uav", .drone),
        ("fpv", .fpv),
        ("kab", .guidedAerialBomb),
        ("cruise_missile", .cruiseMissile),
        ("high_speed_target", .highSpeedTarget),
        ("missile", .missile),
        ("ballistic", .ballisticMissile),
        ("aviation", .aviation),
        ("lancet", nil)
    ])
    func map_whenType_mapsOrFallsBackToNil(type: String, expected: ThreatType?) {
        let threat = ThreatEventDTOMapper.map(.stub(type: type))

        #expect(threat.type == expected)
    }

    @Test
    func map_whenNoType_keepsKindOnly() {
        let threat = ThreatEventDTOMapper.map(.stub(kind: "missile", type: nil))

        #expect(threat.kind == .missile)
        #expect(threat.type == nil)
    }

    // MARK: - map: level

    @Test(arguments: [
        ("high", ThreatLevel.high),
        ("medium", .medium),
        ("low", .low),
        ("critical", .low),
        ("", .low)
    ])
    func map_whenLevel_mapsOrFallsBackToLow(level: String, expected: ThreatLevel) {
        let threat = ThreatEventDTOMapper.map(.stub(level: level))

        #expect(threat.level == expected)
    }

    // MARK: - map: position quality

    @Test(arguments: [
        ("confirmed", ThreatPositionQuality.confirmed),
        ("approx", .approximate),
        ("target_only", .targetOnly),
        ("area", .area)
    ])
    func map_whenPositionQualityKnown_mapsIt(value: String, expected: ThreatPositionQuality) {
        let threat = ThreatEventDTOMapper.map(.stub(positionQuality: value))

        #expect(threat.positionQuality == expected)
    }

    @Test(arguments: [String?.none, "precise"])
    func map_whenPositionQualityMissingOrUnknownWithPosition_isApproximate(value: String?) {
        let threat = ThreatEventDTOMapper.map(.stub(position: Constants.place, positionQuality: value))

        #expect(threat.positionQuality == .approximate)
    }

    @Test(arguments: [String?.none, "precise"])
    func map_whenPositionQualityMissingOrUnknownWithoutPosition_isArea(value: String?) {
        let threat = ThreatEventDTOMapper.map(.stub(position: nil, positionQuality: value))

        #expect(threat.positionQuality == .area)
    }

    // MARK: - map: optional and malformed fields

    @Test
    func map_whenOptionalFieldsMissing_usesSafeDefaults() {
        let dto = ThreatEventDTO.stub(
            position: nil,
            trail: nil,
            accuracyKm: nil,
            speedKmh: nil,
            speedSource: nil,
            movedAt: nil,
            firstSeen: 1_000
        )

        let threat = ThreatEventDTOMapper.map(dto)

        #expect(threat.position == nil)
        #expect(threat.trail.isEmpty)
        #expect(threat.accuracyKm == 0)
        #expect(threat.speedKmh == 0)
        #expect(threat.speedSource == .typical)
        #expect(threat.movedAt == Date(timeIntervalSince1970: 1_000))
        #expect(threat.heading == nil)
        #expect(threat.approachBearing == nil)
        #expect(threat.summary == nil)
    }

    @Test
    func map_whenSpeedNegative_clampsToZero() {
        let threat = ThreatEventDTOMapper.map(.stub(speedKmh: -40))

        #expect(threat.speedKmh == 0)
    }

    @Test(arguments: ["typical", "TRACK", "estimated"])
    func map_whenSpeedSourceNotTrack_isTypical(speedSource: String) {
        let threat = ThreatEventDTOMapper.map(.stub(speedSource: speedSource))

        #expect(threat.speedSource == .typical)
    }

    @Test
    func map_whenTrackPointsMalformed_dropsOnlyThose() {
        let trail: [[Double]] = [[49.1, 30.1, 100], [49.2, 30.2], [], [49.3, 30.3, 200, 7]]

        let threat = ThreatEventDTOMapper.map(.stub(trail: trail))

        #expect(threat.trail == [
            ThreatTrackPoint(coordinate: GeoCoordinate(latitude: 49.1, longitude: 30.1), time: Date(timeIntervalSince1970: 100)),
            ThreatTrackPoint(coordinate: GeoCoordinate(latitude: 49.3, longitude: 30.3), time: Date(timeIntervalSince1970: 200))
        ])
    }

    @Test
    func map_whenCountryWide_keepsCountryCode() {
        let threat = ThreatEventDTOMapper.map(.stub(area: ThreatAreaDTO(name: "Україна", code: "UA", lat: 49, lon: 31)))

        #expect(threat.isCountryWide)
    }
}

// MARK: - Fixtures

private extension ThreatEventDTO {

    static func stub(
        kind: String = "drone",
        type: String? = "shahed",
        level: String = "medium",
        position: ThreatPlaceDTO? = Constants.place,
        trail: [[Double]]? = [],
        area: ThreatAreaDTO = ThreatAreaDTO(name: "Київська область", code: "UA-32", lat: 50.05, lon: 30.77),
        positionQuality: String? = "confirmed",
        accuracyKm: Double? = 5,
        speedKmh: Double? = 150,
        speedSource: String? = "track",
        movedAt: Int? = nil,
        firstSeen: Int = 1_000
    ) -> ThreatEventDTO {
        ThreatEventDTO(
            id: "evt-1",
            kind: kind,
            type: type,
            count: nil,
            level: level,
            confidence: 0.5,
            sources: 1,
            position: position,
            target: nil,
            trail: trail,
            area: area,
            positionQuality: positionQuality,
            accuracyKm: accuracyKm,
            headingDeg: nil,
            fromDeg: nil,
            speedKmh: speedKmh,
            speedSource: speedSource,
            movedAt: movedAt,
            firstSeen: firstSeen,
            updated: firstSeen,
            expires: firstSeen + 1_800,
            summary: nil
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let place = ThreatPlaceDTO(name: "Біла Церква", lat: 49.8, lon: 30.1)

    static let fullEventJSON = """
    {
      "id": "evt-1",
      "kind": "drone",
      "type": "shahed",
      "count": 3,
      "level": "high",
      "confidence": 0.85,
      "sources": 4,
      "position": {"name": "Біла Церква", "lat": 49.8, "lon": 30.1},
      "target": {"name": "Київ", "lat": 50.45, "lon": 30.52},
      "trail": [[49.5, 30.0, 1791935400]],
      "area": {"name": "Київська область", "code": "UA-32", "lat": 50.05, "lon": 30.77},
      "position_quality": "confirmed",
      "accuracy_km": 3.5,
      "heading_deg": 15,
      "from_deg": 190,
      "speed_kmh": 170,
      "speed_source": "track",
      "moved_at": 1791935700,
      "first_seen": 1791935000,
      "updated": 1791935800,
      "expires": 1791937600,
      "summary": "Шахед ×3 курсом на Київ",
      "added_later": {"ignored": true}
    }
    """
}
