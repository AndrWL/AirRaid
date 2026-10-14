//
//  NightReportContentTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``NightReportContent/make(items:regionIDs:now:calendar:)``.
///
/// Covers the night's bounds before and after the morning, merging overlapping alerts, and counting only the user's
/// oblasts. Dates are wall-clock times in the current time zone, as the report formats them.
@MainActor
@Suite
struct NightReportContentTests {

    // MARK: - Night bounds

    @Test
    func make_whenAfterMorning_coversEveningToMorning() {
        let sut = makeSUT(items: [], now: time(day: 14, hour: 10))

        #expect(sut.title == "Ніч на 14 жовтня")
        #expect(sut.periodText == "20:00 – 08:00")
        #expect(sut.isQuiet)
    }

    @Test
    func make_whenBeforeMorning_endsNow() {
        let ongoing = alertItem(places: [.stub(startedAt: time(day: 14, hour: 2), endedAt: nil)])

        let sut = makeSUT(items: [ongoing], now: time(day: 14, hour: 3, minute: 30))

        #expect(sut.periodText == "20:00 – 03:30")
        #expect(sut.alertDuration == 1.5 * Constants.hour)
        #expect(sut.alertCount == 1)
    }

    @Test
    func make_whenAlertsCrossNightBounds_clipsThem() {
        let item = alertItem(places: [
            .stub(alertID: "a1", startedAt: time(day: 13, hour: 19), endedAt: time(day: 13, hour: 21)),
            .stub(alertID: "a2", startedAt: time(day: 14, hour: 7), endedAt: time(day: 14, hour: 9))
        ])

        let sut = makeSUT(items: [item], now: time(day: 14, hour: 10))

        #expect(sut.alertDuration == 2 * Constants.hour)
        #expect(sut.alertCount == 2)
    }

    @Test
    func make_whenAlertOutsideNight_ignoresIt() {
        let item = alertItem(places: [.stub(startedAt: time(day: 13, hour: 12), endedAt: time(day: 13, hour: 13))])

        let sut = makeSUT(items: [item], now: time(day: 14, hour: 10))

        #expect(sut.alertCount == 0)
        #expect(sut.alertDurationText == nil)
    }

    @Test
    func make_whenClocksGoForwardOvernight_endsAtEightOnTheWallClock() {
        // Kyiv moves from UTC+2 to UTC+3 at 03:00 on 29 March 2026.
        let item = alertItem(places: [.stub(startedAt: kyivTime(day: 29, hour: 7), endedAt: kyivTime(day: 29, hour: 9))])

        let sut = makeSUT(items: [item], now: kyivTime(day: 29, hour: 10), calendar: Constants.kyivCalendar)

        #expect(sut.alertDuration == Constants.hour)
    }

    @Test
    func make_whenClocksWentForwardDayBefore_startsAtEightPMOnTheWallClock() {
        let item = alertItem(places: [.stub(startedAt: kyivTime(day: 29, hour: 19), endedAt: kyivTime(day: 29, hour: 21))])

        let sut = makeSUT(items: [item], now: kyivTime(day: 30, hour: 10), calendar: Constants.kyivCalendar)

        #expect(sut.alertDuration == Constants.hour)
    }

    // MARK: - Alert duration

    @Test
    func make_whenAlertsOverlap_mergesTheirTime() {
        let items = [
            alertItem(id: "alert:1", places: [
                .stub(alertID: "a1", startedAt: time(day: 13, hour: 21), endedAt: time(day: 13, hour: 23)),
                .stub(alertID: "a2", startedAt: time(day: 13, hour: 22), endedAt: time(day: 14, hour: 0, minute: 30))
            ]),
            alertItem(id: "alert:2", places: [
                .stub(alertID: "a3", startedAt: time(day: 14, hour: 2), endedAt: time(day: 14, hour: 3))
            ])
        ]

        let sut = makeSUT(items: items, now: time(day: 14, hour: 10))

        #expect(sut.alertDuration == 4.5 * Constants.hour)
        #expect(sut.alertDurationText == "4 год 30 хв")
        #expect(sut.alertCount == 3)
    }

    // MARK: - User's oblasts

    @Test
    func make_whenAlertsElsewhereOrNotAirRaid_countsOnlyUsersAirRaids() {
        let night = (time(day: 13, hour: 22), time(day: 13, hour: 23))
        let items = [
            alertItem(id: "alert:mine", places: [.stub(startedAt: night.0, endedAt: night.1)]),
            alertItem(id: "alert:other", regionID: "UA-46", places: [.stub(startedAt: night.0, endedAt: night.1)]),
            alertItem(id: "alert:shelling", kind: .artilleryShelling, places: [.stub(startedAt: night.0, endedAt: night.1)])
        ]

        let sut = makeSUT(items: items, now: time(day: 14, hour: 10))

        #expect(sut.alertCount == 1)
        #expect(sut.alertDuration == Constants.hour)
    }

    @Test
    func make_whenThreatsAcrossCountry_countsNearbyOnlyInUsersOblasts() {
        let evening = time(day: 13, hour: 23)
        let items = [
            threatItem(id: "threat:1", kind: .drone, count: 3, regionIDs: ["UA-32"], createdAt: evening),
            threatItem(id: "threat:2", kind: .drone, count: nil, regionIDs: ["UA-18", "UA-32"], createdAt: evening),
            threatItem(id: "threat:3", kind: .missile, count: nil, regionIDs: ["UA-32"], createdAt: evening),
            threatItem(id: "threat:4", kind: .missile, count: 5, regionIDs: ["UA-46"], createdAt: evening),
            threatItem(id: "threat:5", kind: .drone, count: 2, regionIDs: ["UA-32"], createdAt: time(day: 13, hour: 19))
        ]

        let sut = makeSUT(items: items, now: time(day: 14, hour: 10))

        #expect(sut.nearbyThreats.map(\.id) == ["drone", "missile"])
        #expect(sut.nearbyThreats.map(\.count) == [4, 1])
        #expect(sut.countryThreatCount == 10)
        #expect(!sut.isQuiet)
    }

    @Test
    func make_whenNoPlaces_reportsCountryOnly() {
        let item = threatItem(id: "threat:1", kind: .drone, count: 2, regionIDs: ["UA-32"], createdAt: time(day: 13, hour: 23))

        let sut = makeSUT(items: [item], regionIDs: [], now: time(day: 14, hour: 10))

        #expect(!sut.hasPlaces)
        #expect(sut.nearbyThreats.isEmpty)
        #expect(sut.countryThreatCount == 2)
    }
}

// MARK: - Helpers

private extension NightReportContentTests {

    func makeSUT(
        items: [FeedItem],
        regionIDs: Set<String> = ["UA-32"],
        now: Date,
        calendar: Calendar = Constants.calendar
    ) -> NightReportContent {
        NightReportContent.make(items: items, regionIDs: regionIDs, now: now, calendar: calendar)
    }

    /// A wall-clock time in October 2026.
    func time(day: Int, hour: Int, minute: Int = 0) -> Date {
        Constants.calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? .distantPast
    }

    /// A wall-clock time in Kyiv in March 2026, around the switch to summer time.
    func kyivTime(day: Int, hour: Int) -> Date {
        Constants.kyivCalendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour)) ?? .distantPast
    }

    func alertItem(
        id: String = "alert:UA-32:airRaid:0",
        kind: RegionAlertKind = .airRaid,
        regionID: String = "UA-32",
        places: [FeedAlertPlace]
    ) -> FeedItem {
        FeedItem.stub(
            id: id,
            createdAt: places.map(\.startedAt).min() ?? FeedFixtures.origin,
            updatedAt: places.map { $0.endedAt ?? $0.startedAt }.max() ?? FeedFixtures.origin,
            isActive: places.contains { $0.endedAt == nil },
            regionIDs: [regionID],
            content: .alert(.stub(kind: kind, regionID: regionID, places: places))
        )
    }

    func threatItem(
        id: String,
        kind: ThreatKind,
        count: Int?,
        regionIDs: Set<String>,
        createdAt: Date
    ) -> FeedItem {
        FeedItem.stub(
            id: id,
            createdAt: createdAt,
            updatedAt: createdAt.addingTimeInterval(1_800),
            isActive: false,
            regionIDs: regionIDs,
            content: .threat(.stub(threatID: id, kind: kind, count: count))
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let hour: TimeInterval = 3_600

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    static let kyivCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Kyiv") ?? .current
        return calendar
    }()
}
