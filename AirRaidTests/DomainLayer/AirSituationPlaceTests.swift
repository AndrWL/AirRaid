//
//  AirSituationPlaceTests.swift
//  AirRaidTests
//

import Testing
@testable import AirRaid

/// Tests for ``AirSituation/airRaidAlerts(regionID:district:)`` and
/// ``AirSituation/airRaidAlertSummary(regionID:district:)``: the alert at the home's point, as the widgets show it.
///
/// Covers each scope read the way the map fills it, Sevastopol under a Crimea-wide alert, and the summary's level and
/// start.
@Suite
struct AirSituationPlaceTests {

    // MARK: - airRaidAlerts(regionID:district:)

    @Test
    func airRaidAlerts_whenOblastAlerted_returnsItForEveryPointInside() {
        let alert = RegionAlert.stub(scope: .oblast)
        let sut = makeSUT(alerts: [alert])

        let alerts = sut.airRaidAlerts(regionID: "UA-32", district: Constants.obukhiv)

        #expect(alerts == [alert])
    }

    @Test(arguments: [RegionAlertScope.raion, .hromada])
    func airRaidAlerts_whenPointsRaionOrItsHromadaAlerted_returnsIt(scope: RegionAlertScope) {
        let alert = RegionAlert.stub(scope: scope, district: Constants.bucha)
        let sut = makeSUT(alerts: [alert])

        let alerts = sut.airRaidAlerts(regionID: "UA-32", district: Constants.bucha)

        #expect(alerts == [alert])
    }

    @Test(arguments: [RegionAlertScope.raion, .hromada])
    func airRaidAlerts_whenOtherRaionAlerted_returnsNothing(scope: RegionAlertScope) {
        let sut = makeSUT(alerts: [.stub(scope: scope, district: Constants.bucha)])

        let alerts = sut.airRaidAlerts(regionID: "UA-32", district: Constants.obukhiv)

        #expect(alerts.isEmpty)
    }

    @Test
    func airRaidAlerts_whenPointOutsideEveryRaion_ignoresRaionAlerts() {
        let sut = makeSUT(alerts: [.stub(scope: .raion, district: Constants.bucha)])

        let alerts = sut.airRaidAlerts(regionID: "UA-32", district: nil)

        #expect(alerts.isEmpty)
    }

    @Test(arguments: ["UA-30", "UA-40"])
    func airRaidAlerts_whenKyivOrSevastopolCityAlerted_returnsIt(regionID: String) {
        let alert = RegionAlert.stub(scope: .city, regionID: regionID)
        let sut = makeSUT(alerts: [alert])

        let alerts = sut.airRaidAlerts(regionID: regionID, district: nil)

        #expect(alerts == [alert])
    }

    @Test
    func airRaidAlerts_whenOtherCityInOblastAlerted_returnsNothing() {
        let sut = makeSUT(alerts: [.stub(scope: .city, name: "м. Харків", regionID: "UA-63")])

        let alerts = sut.airRaidAlerts(regionID: "UA-63", district: nil)

        #expect(alerts.isEmpty)
    }

    @Test
    func airRaidAlerts_whenCrimeaWideAlert_returnsItForSevastopol() {
        let alert = RegionAlert.stub(scope: .oblast, name: "АР Крим", regionID: "UA-43")
        let sut = makeSUT(alerts: [alert])

        let alerts = sut.airRaidAlerts(regionID: "UA-40", district: nil)

        #expect(alerts == [alert])
    }

    @Test
    func airRaidAlerts_whenPointOutsideEveryOutline_returnsNothing() {
        let sut = makeSUT(alerts: [.stub(scope: .oblast), .stub(id: "a2", scope: .hromada, district: Constants.bucha)])

        let alerts = sut.airRaidAlerts(regionID: nil, district: nil)

        #expect(alerts.isEmpty)
    }

    @Test
    func airRaidAlerts_whenNotAirRaidOrUnknownScope_returnsNothing() {
        let sut = makeSUT(alerts: [
            .stub(id: "shelling", kind: .artilleryShelling, scope: .oblast),
            .stub(id: "unknown", scope: .unknown, district: Constants.bucha)
        ])

        let alerts = sut.airRaidAlerts(regionID: "UA-32", district: Constants.bucha)

        #expect(alerts.isEmpty)
    }

    // MARK: - airRaidAlertSummary(regionID:district:)

    @Test
    func airRaidAlertSummary_whenNoAlertAtPoint_returnsNil() {
        let sut = makeSUT(alerts: [.stub(scope: .hromada, district: Constants.bucha)])

        let summary = sut.airRaidAlertSummary(regionID: "UA-32", district: Constants.obukhiv)

        #expect(summary == nil)
    }

    @Test
    func airRaidAlertSummary_whenSeveralAlerts_returnsHighestLevelAndEarliestStart() throws {
        let sut = makeSUT(alerts: [
            .stub(id: "oblast", level: .yellow, scope: .oblast, startedAt: FeedFixtures.date(600)),
            .stub(id: "hromada", level: .red, scope: .hromada, district: Constants.bucha, startedAt: FeedFixtures.date(1_200)),
            .stub(id: "elsewhere", level: .yellow, scope: .raion, district: Constants.obukhiv, startedAt: FeedFixtures.date(0))
        ])

        let summary = try #require(sut.airRaidAlertSummary(regionID: "UA-32", district: Constants.bucha))

        #expect(summary.level == .red)
        #expect(summary.startedAt == FeedFixtures.date(600))
    }

    @Test
    func airRaidAlertSummary_whenAlertHasNoLevel_returnsRed() throws {
        let sut = makeSUT(alerts: [.stub(level: nil, scope: .oblast)])

        let summary = try #require(sut.airRaidAlertSummary(regionID: "UA-32", district: nil))

        #expect(summary.level == .red)
    }

    @Test
    func airRaidAlertSummary_whenOnlyYellowAlerts_returnsYellow() throws {
        let sut = makeSUT(alerts: [.stub(level: .yellow, scope: .raion, district: Constants.bucha)])

        let summary = try #require(sut.airRaidAlertSummary(regionID: "UA-32", district: Constants.bucha))

        #expect(summary.level == .yellow)
    }
}

// MARK: - Helpers

private extension AirSituationPlaceTests {

    func makeSUT(alerts: [RegionAlert]) -> AirSituation {
        AirSituation(alerts: alerts, threats: [])
    }
}

// MARK: - Constants

private enum Constants {
    static let bucha = DistrictKey(regionID: "UA-32", name: "Бучанський")
    static let obukhiv = DistrictKey(regionID: "UA-32", name: "Обухівський")
}
