//
//  RegionAlertDTOMapperTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``RegionAlertDTOMapper``.
///
/// Covers a full alert decoded from the relayed JSON, every known `kind`, level and `location_type` with their
/// fallbacks, Kyiv and Sevastopol filed under their own region codes, and the raion key of raion and hromada alerts.
@Suite
struct RegionAlertDTOMapperTests {

    // MARK: - map: a full alert

    @Test
    func map_whenFullAlertDecoded_mapsEveryField() throws {
        let dto = try JSONDecoder().decode(RegionAlertDTO.self, from: Data(Constants.hromadaJSON.utf8))

        let alert = RegionAlertDTOMapper.map(dto)

        #expect(alert == RegionAlert(
            id: "1234",
            kind: .airRaid,
            level: .yellow,
            scope: .hromada,
            name: "Покровська територіальна громада",
            regionID: "UA-12",
            district: DistrictKey(regionID: "UA-12", name: "Нікопольський"),
            startedAt: Date(timeIntervalSince1970: 1_791_935_000)
        ))
    }

    // MARK: - map: kind and level

    @Test(arguments: [
        ("air_raid", RegionAlertKind.airRaid),
        ("artillery_shelling", .artilleryShelling),
        ("urban_fights", .urbanFights),
        ("chemical", .chemical),
        ("nuclear", .nuclear),
        ("drone_attack", .unknown),
        ("", .unknown)
    ])
    func map_whenKind_mapsOrFallsBackToUnknown(kind: String, expected: RegionAlertKind) {
        let alert = RegionAlertDTOMapper.map(.stub(kind: kind))

        #expect(alert.kind == expected)
    }

    @Test(arguments: [
        (String?.some("red"), RegionAlertLevel?.some(.red)),
        ("yellow", .yellow),
        (nil, nil),
        ("orange", nil)
    ])
    func map_whenLevel_mapsOrLeavesItOut(level: String?, expected: RegionAlertLevel?) {
        let alert = RegionAlertDTOMapper.map(.stub(level: level))

        #expect(alert.level == expected)
    }

    @Test
    func map_whenLevelUnknown_stillFillsTheMapRed() {
        let alert = RegionAlertDTOMapper.map(.stub(level: "orange", locationType: "oblast", name: "Київська область"))

        let coverage = AirSituation(alerts: [alert], threats: []).airRaidCoverage

        #expect(coverage.regions == ["UA-32": .red])
    }

    // MARK: - map: scope and region

    @Test(arguments: [
        ("oblast", RegionAlertScope.oblast),
        ("raion", .raion),
        ("hromada", .hromada),
        ("city", .city),
        ("unknown", .unknown),
        ("village", .unknown)
    ])
    func map_whenLocationType_mapsOrFallsBackToUnknown(locationType: String, expected: RegionAlertScope) {
        let alert = RegionAlertDTOMapper.map(.stub(locationType: locationType))

        #expect(alert.scope == expected)
    }

    @Test(arguments: [
        ("м. Київ", "UA-32", "UA-30"),
        ("м. Севастополь", "UA-43", "UA-40"),
        ("м. Харків", "UA-63", "UA-63")
    ])
    func map_whenCity_filesKyivAndSevastopolUnderTheirOwnRegion(name: String, code: String, expected: String) {
        let alert = RegionAlertDTOMapper.map(.stub(locationType: "city", name: name, code: code))

        #expect(alert.regionID == expected)
        #expect(alert.district == nil)
    }

    // MARK: - map: district

    @Test
    func map_whenRaion_keysDistrictByShortName() {
        let alert = RegionAlertDTOMapper.map(.stub(locationType: "raion", name: "Бучанський район", code: "UA-32"))

        #expect(alert.district == DistrictKey(regionID: "UA-32", name: "Бучанський"))
    }

    @Test
    func map_whenHromada_keysDistrictByItsRaion() {
        let dto = RegionAlertDTO.stub(locationType: "hromada", name: "Ірпінська громада", raion: "Бучанський район", code: "UA-32")

        let alert = RegionAlertDTOMapper.map(dto)

        #expect(alert.district == DistrictKey(regionID: "UA-32", name: "Бучанський"))
    }

    @Test
    func map_whenHromadaWithoutRaion_hasNoDistrict() {
        let alert = RegionAlertDTOMapper.map(.stub(locationType: "hromada", name: "Ірпінська громада", raion: nil))

        #expect(alert.district == nil)
    }

    @Test(arguments: ["oblast", "city", "unknown"])
    func map_whenNotRaionOrHromada_hasNoDistrict(locationType: String) {
        let alert = RegionAlertDTOMapper.map(.stub(locationType: locationType, raion: "Бучанський район"))

        #expect(alert.district == nil)
    }
}

// MARK: - Fixtures

private extension RegionAlertDTO {

    static func stub(
        kind: String = "air_raid",
        level: String? = nil,
        locationType: String = "raion",
        name: String = "Бучанський район",
        raion: String? = nil,
        code: String = "UA-32"
    ) -> RegionAlertDTO {
        RegionAlertDTO(
            uid: "1",
            kind: kind,
            level: level,
            locationType: locationType,
            name: name,
            oblast: nil,
            raion: raion,
            code: code,
            since: 1_000
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let hromadaJSON = """
    {
      "uid": "1234",
      "kind": "air_raid",
      "level": "yellow",
      "location_type": "hromada",
      "name": "Покровська територіальна громада",
      "oblast": "Дніпропетровська область",
      "raion": "Нікопольський район",
      "code": "UA-12",
      "since": 1791935000,
      "threats": ["drones"],
      "oblast_uid": 9
    }
    """
}
