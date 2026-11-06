//
//  AirRaidCoverageTests.swift
//  AirRaidTests
//

import Testing
@testable import AirRaid

/// Tests for ``AirSituation/airRaidCoverage``: which oblasts and raions the map fills, and in which colour.
///
/// Covers each alert scope (oblast, Kyiv and Sevastopol, other cities, raion, hromada), Sevastopol under a
/// Crimea-wide alert, the level (a missing one is red) and how several alerts on one place combine.
@Suite
struct AirRaidCoverageTests {

    // MARK: - airRaidCoverage: scope

    @Test(arguments: [
        (RegionAlertLevel?.none, RegionAlertLevel.red),
        (.yellow, .yellow),
        (.red, .red)
    ])
    func airRaidCoverage_whenOblastAlert_fillsOblastWithItsLevel(level: RegionAlertLevel?, expected: RegionAlertLevel) {
        let sut = makeSUT(alerts: [.stub(level: level, scope: .oblast, name: "Київська область")])

        let coverage = sut.airRaidCoverage

        #expect(coverage == AirRaidCoverage(regions: ["UA-32": expected], districts: [:]))
    }

    @Test(arguments: [Constants.kyivID, Constants.sevastopolID])
    func airRaidCoverage_whenKyivOrSevastopolCityAlert_fillsTheCityRegion(regionID: String) {
        let sut = makeSUT(alerts: [.stub(level: .yellow, scope: .city, regionID: regionID)])

        let coverage = sut.airRaidCoverage

        #expect(coverage == AirRaidCoverage(regions: [regionID: .yellow], districts: [:]))
    }

    @Test
    func airRaidCoverage_whenOtherCityAlert_fillsNothing() {
        let sut = makeSUT(alerts: [.stub(scope: .city, name: "м. Харків", regionID: "UA-63")])

        let coverage = sut.airRaidCoverage

        #expect(coverage == .none)
    }

    @Test
    func airRaidCoverage_whenRaionAlert_fillsWholeRaion() {
        let sut = makeSUT(alerts: [.stub(level: .yellow, scope: .raion, district: Constants.bucha)])

        let coverage = sut.airRaidCoverage

        #expect(coverage.regions.isEmpty)
        #expect(coverage.districts == [Constants.bucha: RegionAlertCoverage(extent: .whole, level: .yellow)])
    }

    @Test
    func airRaidCoverage_whenHromadaAlert_fillsItsRaionPartially() {
        let sut = makeSUT(alerts: [.stub(scope: .hromada, name: "Ірпінська громада", district: Constants.bucha)])

        let coverage = sut.airRaidCoverage

        #expect(coverage.regions.isEmpty)
        #expect(coverage.districts == [Constants.bucha: RegionAlertCoverage(extent: .partial, level: .red)])
    }

    @Test(arguments: [RegionAlertScope.raion, .hromada])
    func airRaidCoverage_whenRaionLevelAlertHasNoDistrict_fillsNothing(scope: RegionAlertScope) {
        let sut = makeSUT(alerts: [.stub(scope: scope, district: nil)])

        let coverage = sut.airRaidCoverage

        #expect(coverage == .none)
    }

    @Test
    func airRaidCoverage_whenScopeUnknown_fillsNothing() {
        let sut = makeSUT(alerts: [.stub(scope: .unknown, district: Constants.bucha)])

        let coverage = sut.airRaidCoverage

        #expect(coverage == .none)
    }

    @Test(arguments: RegionAlertKind.allCases.filter { $0 != .airRaid })
    func airRaidCoverage_whenAlertIsNotAirRaid_fillsNothing(kind: RegionAlertKind) {
        let sut = makeSUT(alerts: [
            .stub(id: "oblast", kind: kind, scope: .oblast),
            .stub(id: "raion", kind: kind, scope: .raion, district: Constants.bucha)
        ])

        let coverage = sut.airRaidCoverage

        #expect(coverage == .none)
    }

    @Test
    func airRaidCoverage_whenNoAlerts_fillsNothing() {
        let sut = makeSUT(alerts: [])

        let coverage = sut.airRaidCoverage

        #expect(coverage == .none)
    }

    // MARK: - airRaidCoverage: Crimea and Sevastopol

    @Test
    func airRaidCoverage_whenCrimeaWideAlert_alsoFillsSevastopol() {
        let sut = makeSUT(alerts: [.stub(level: .yellow, scope: .oblast, name: "АР Крим", regionID: Constants.crimeaID)])

        let coverage = sut.airRaidCoverage

        #expect(coverage.regions == [Constants.crimeaID: .yellow, Constants.sevastopolID: .yellow])
    }

    @Test
    func airRaidCoverage_whenSevastopolOblastAlert_leavesCrimeaClear() {
        let sut = makeSUT(alerts: [.stub(scope: .oblast, name: "м. Севастополь", regionID: Constants.sevastopolID)])

        let coverage = sut.airRaidCoverage

        #expect(coverage.regions == [Constants.sevastopolID: .red])
    }

    @Test(arguments: [false, true])
    func airRaidCoverage_whenCrimeaYellowAndSevastopolRed_keepsSevastopolRedInAnyOrder(crimeaFirst: Bool) {
        let crimea = RegionAlert.stub(id: "crimea", level: .yellow, scope: .oblast, regionID: Constants.crimeaID)
        let sevastopol = RegionAlert.stub(id: "sevastopol", level: .red, scope: .city, regionID: Constants.sevastopolID)
        let sut = makeSUT(alerts: crimeaFirst ? [crimea, sevastopol] : [sevastopol, crimea])

        let coverage = sut.airRaidCoverage

        #expect(coverage.regions == [Constants.crimeaID: .yellow, Constants.sevastopolID: .red])
    }

    // MARK: - airRaidCoverage: several alerts on one place

    @Test(arguments: [false, true])
    func airRaidCoverage_whenOblastHasYellowAndRedAlerts_fillsRedInAnyOrder(redFirst: Bool) {
        let yellow = RegionAlert.stub(id: "yellow", level: .yellow, scope: .oblast)
        let red = RegionAlert.stub(id: "red", level: .red, scope: .oblast)
        let sut = makeSUT(alerts: redFirst ? [red, yellow] : [yellow, red])

        let coverage = sut.airRaidCoverage

        #expect(coverage.regions == ["UA-32": .red])
    }

    @Test(arguments: [false, true])
    func airRaidCoverage_whenRaionYellowAndHromadaRed_fillsWholeRaionRed(hromadaFirst: Bool) {
        let raion = RegionAlert.stub(id: "raion", level: .yellow, scope: .raion, district: Constants.bucha)
        let hromada = RegionAlert.stub(id: "hromada", level: .red, scope: .hromada, district: Constants.bucha)
        let sut = makeSUT(alerts: hromadaFirst ? [hromada, raion] : [raion, hromada])

        let coverage = sut.airRaidCoverage

        #expect(coverage.districts == [Constants.bucha: RegionAlertCoverage(extent: .whole, level: .red)])
    }

    @Test
    func airRaidCoverage_whenRaionsShareNameInDifferentOblasts_keepsThemApart() {
        let namesake = DistrictKey(regionID: "UA-05", name: "Бучанський")
        let sut = makeSUT(alerts: [
            .stub(id: "kyiv", level: .yellow, scope: .raion, district: Constants.bucha),
            .stub(id: "vinnytsia", level: .red, scope: .hromada, regionID: "UA-05", district: namesake)
        ])

        let coverage = sut.airRaidCoverage

        #expect(coverage.districts == [
            Constants.bucha: RegionAlertCoverage(extent: .whole, level: .yellow),
            namesake: RegionAlertCoverage(extent: .partial, level: .red)
        ])
    }

    @Test
    func airRaidCoverage_whenOblastAndRaionAlerts_fillsBoth() {
        let sut = makeSUT(alerts: [
            .stub(id: "oblast", level: .yellow, scope: .oblast),
            .stub(id: "raion", level: .red, scope: .raion, district: Constants.bucha)
        ])

        let coverage = sut.airRaidCoverage

        #expect(coverage.regions == ["UA-32": .yellow])
        #expect(coverage.districts == [Constants.bucha: RegionAlertCoverage(extent: .whole, level: .red)])
    }

    // MARK: - RegionAlertCoverage.combined

    @Test(arguments: [
        (RegionAlertExtent.partial, RegionAlertLevel.yellow, RegionAlertExtent.partial, RegionAlertLevel.yellow),
        (.partial, .red, .whole, .yellow),
        (.whole, .yellow, .partial, .red)
    ])
    func combined_whenTwoCoverages_takesHighestOfEach(
        extent: RegionAlertExtent,
        level: RegionAlertLevel,
        otherExtent: RegionAlertExtent,
        otherLevel: RegionAlertLevel
    ) {
        let sut = RegionAlertCoverage(extent: extent, level: level)
        let other = RegionAlertCoverage(extent: otherExtent, level: otherLevel)

        let combined = sut.combined(with: other)

        #expect(combined == RegionAlertCoverage(extent: max(extent, otherExtent), level: max(level, otherLevel)))
        #expect(combined == other.combined(with: sut))
    }

    // MARK: - isAlerted(at:regions:districts:)

    @Test
    func isAlerted_whenPointInAlertedOblast_returnsTrue() {
        let sut = AirRaidCoverage(regions: ["UA-32": .yellow], districts: [:])

        let isAlerted = sut.isAlerted(at: Constants.westPoint, regions: [Constants.oblast], districts: Constants.raions)

        #expect(isAlerted)
    }

    @Test
    func isAlerted_whenPointInOblastHole_returnsFalse() {
        let hole = MapFixtures.square(center: Constants.westPoint, halfSize: 0.1).exterior
        let oblast = RegionBoundary.stub(polygons: [
            MapFixtures.rectangle(south: 49, west: 29, north: 51, east: 31, holes: [hole])
        ])
        let sut = AirRaidCoverage(regions: ["UA-32": .red], districts: [:])

        let isAlerted = sut.isAlerted(at: Constants.westPoint, regions: [oblast], districts: [])

        #expect(!isAlerted)
    }

    @Test(arguments: [RegionAlertExtent.whole, .partial])
    func isAlerted_whenPointInAlertedRaion_returnsTrue(extent: RegionAlertExtent) {
        let sut = AirRaidCoverage(
            regions: [:],
            districts: [Constants.bucha: RegionAlertCoverage(extent: extent, level: .yellow)]
        )

        let isAlerted = sut.isAlerted(at: Constants.westPoint, regions: [Constants.oblast], districts: Constants.raions)

        #expect(isAlerted)
    }

    @Test
    func isAlerted_whenPointInOtherRaionOfPartlyAlertedOblast_returnsFalse() {
        let sut = AirRaidCoverage(
            regions: [:],
            districts: [Constants.bucha: RegionAlertCoverage(extent: .whole, level: .red)]
        )

        let isAlerted = sut.isAlerted(at: Constants.eastPoint, regions: [Constants.oblast], districts: Constants.raions)

        #expect(!isAlerted)
    }

    @Test
    func isAlerted_whenOtherOblastAlerted_returnsFalse() {
        let sut = AirRaidCoverage(regions: ["UA-05": .red], districts: [:])

        let isAlerted = sut.isAlerted(at: Constants.westPoint, regions: [Constants.oblast], districts: Constants.raions)

        #expect(!isAlerted)
    }
}

// MARK: - Helpers

private extension AirRaidCoverageTests {

    func makeSUT(alerts: [RegionAlert]) -> AirSituation {
        AirSituation(alerts: alerts, threats: [])
    }
}

// MARK: - Constants

private enum Constants {
    static let kyivID = "UA-30"
    static let sevastopolID = "UA-40"
    static let crimeaID = "UA-43"
    static let bucha = DistrictKey(regionID: "UA-32", name: "Бучанський")

    /// Kyiv Oblast as a square, split into a western (Bucha) and an eastern (Obukhiv) raion.
    static let oblast = RegionBoundary.stub(polygons: [MapFixtures.rectangle(south: 49, west: 29, north: 51, east: 31)])
    static let raions = [
        DistrictBoundary.stub(name: "Бучанський", polygons: [MapFixtures.rectangle(south: 49, west: 29, north: 51, east: 30)]),
        DistrictBoundary.stub(name: "Обухівський", polygons: [MapFixtures.rectangle(south: 49, west: 30, north: 51, east: 31)])
    ]
    static let westPoint = GeoCoordinate(latitude: 50, longitude: 29.5)
    static let eastPoint = GeoCoordinate(latitude: 50, longitude: 30.5)
}
