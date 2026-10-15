//
//  FeedBuilderAlertTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``FeedBuilder/apply(_:now:)`` with official alerts.
///
/// Covers grouping by oblast, kind and time, ending places, level changes, stale alerts, and a repeated `alert_on`.
@Suite
struct FeedBuilderAlertTests {

    // MARK: - apply: grouping

    @Test
    func apply_whenAlertStarts_createsBubbleWithStartedLine() throws {
        var sut = makeSUT()
        let alert = RegionAlert.stub(startedAt: FeedFixtures.date(0))

        let entries = sut.apply([.alertStarted(alert, previous: nil)], now: FeedFixtures.date(30))

        let item = try #require(sut.items.values.first)
        let line = FeedLine(date: FeedFixtures.date(0), event: .alertStarted(placeName: "Бучанський район"))
        #expect(sut.items.count == 1)
        #expect(item.isActive)
        #expect(item.lines == [line])
        #expect(item.content == .alert(.stub(places: [.stub(startedAt: FeedFixtures.date(0))])))
        #expect(entries == [FeedEntry(item: item, line: line)])
    }

    @Test
    func apply_whenAlertsOfOneOblastAndKindWithinGroupWindow_shareBubble() throws {
        var sut = makeSUT()
        let first = RegionAlert.stub(id: "a1", startedAt: FeedFixtures.date(0))
        let second = RegionAlert.stub(id: "a2", level: .red, name: "Броварський район", startedAt: FeedFixtures.date(100))
        let third = RegionAlert.stub(id: "a3", name: "Обухівський район", startedAt: FeedFixtures.date(220))

        let entries = sut.apply(
            [.alertStarted(first, previous: nil), .alertStarted(second, previous: nil), .alertStarted(third, previous: nil)],
            now: FeedFixtures.date(220)
        )

        let item = try #require(sut.items.values.first)
        guard case .alert(let group) = item.content else {
            Issue.record("Expected an alert bubble")
            return
        }
        #expect(sut.items.count == 1)
        #expect(group.places.map(\.alertID) == ["a1", "a2", "a3"])
        #expect(group.level == .red)
        #expect(item.lines.count == 3)
        #expect(entries.count == 3)
    }

    @Test
    func apply_whenAlertStartsAfterGroupWindow_createsSecondBubble() {
        var sut = makeSUT(started: [.stub(id: "a1", startedAt: FeedFixtures.date(0))])

        _ = sut.apply([.alertStarted(.stub(id: "a2", startedAt: FeedFixtures.date(121)), previous: nil)], now: FeedFixtures.date(121))

        #expect(sut.items.count == 2)
    }

    @Test(arguments: [
        RegionAlert.stub(id: "a2", regionID: "UA-18", startedAt: FeedFixtures.date(10)),
        RegionAlert.stub(id: "a2", kind: .artilleryShelling, startedAt: FeedFixtures.date(10))
    ])
    func apply_whenAlertOfOtherOblastOrKind_createsSecondBubble(alert: RegionAlert) {
        var sut = makeSUT(started: [.stub(id: "a1", startedAt: FeedFixtures.date(0))])

        _ = sut.apply([.alertStarted(alert, previous: nil)], now: FeedFixtures.date(10))

        #expect(sut.items.count == 2)
    }

    @Test
    func apply_whenGroupEnded_newAlertStartsNewBubble() {
        let first = RegionAlert.stub(id: "a1", startedAt: FeedFixtures.date(0))
        var sut = makeSUT(started: [first])
        _ = sut.apply([.alertEnded(first, at: FeedFixtures.date(30))], now: FeedFixtures.date(30))

        _ = sut.apply([.alertStarted(.stub(id: "a2", startedAt: FeedFixtures.date(60)), previous: nil)], now: FeedFixtures.date(60))

        #expect(sut.items.count == 2)
        #expect(sut.items.values.filter(\.isActive).count == 1)
    }

    // MARK: - apply: ending

    @Test
    func apply_whenOnePlaceOfGroupEnds_keepsBubbleActive() throws {
        let first = RegionAlert.stub(id: "a1", startedAt: FeedFixtures.date(0))
        let second = RegionAlert.stub(id: "a2", name: "Броварський район", startedAt: FeedFixtures.date(60))
        var sut = makeSUT(started: [first, second])

        let entries = sut.apply([.alertEnded(first, at: FeedFixtures.date(600))], now: FeedFixtures.date(600))

        let item = try #require(sut.items.values.first)
        let line = FeedLine(date: FeedFixtures.date(600), event: .alertEnded(placeName: "Бучанський район", duration: 600))
        guard case .alert(let group) = item.content else {
            Issue.record("Expected an alert bubble")
            return
        }
        #expect(item.isActive)
        #expect(group.places.map(\.endedAt) == [FeedFixtures.date(600), nil])
        #expect(entries == [FeedEntry(item: item, line: line)])
    }

    @Test
    func apply_whenAllPlacesOfGroupEnd_closesBubble() throws {
        let first = RegionAlert.stub(id: "a1", startedAt: FeedFixtures.date(0))
        let second = RegionAlert.stub(id: "a2", name: "Броварський район", startedAt: FeedFixtures.date(60))
        var sut = makeSUT(started: [first, second])

        _ = sut.apply(
            [.alertEnded(first, at: FeedFixtures.date(600)), .alertEnded(second, at: FeedFixtures.date(900))],
            now: FeedFixtures.date(900)
        )

        let item = try #require(sut.items.values.first)
        #expect(!item.isActive)
        #expect(item.updatedAt == FeedFixtures.date(900))
        #expect(item.lines.last?.event == .alertEnded(placeName: "Броварський район", duration: 840))
    }

    @Test
    func apply_whenUnknownAlertEnds_addsNothing() {
        var sut = makeSUT()

        let entries = sut.apply([.alertEnded(.stub(), at: FeedFixtures.date(60))], now: FeedFixtures.date(60))

        #expect(entries.isEmpty)
        #expect(sut.items.isEmpty)
    }

    // MARK: - apply: level

    @Test
    func apply_whenAlertLevelChanges_addsLevelLine() throws {
        let yellow = RegionAlert.stub(level: .yellow, startedAt: FeedFixtures.date(0))
        let red = RegionAlert.stub(level: .red, startedAt: FeedFixtures.date(0))
        var sut = makeSUT(started: [yellow])

        let entries = sut.apply([.alertStarted(red, previous: yellow)], now: FeedFixtures.date(300))

        let item = try #require(sut.items.values.first)
        let line = FeedLine(date: FeedFixtures.date(300), event: .alertLevelChanged(.red))
        guard case .alert(let group) = item.content else {
            Issue.record("Expected an alert bubble")
            return
        }
        #expect(group.level == .red)
        #expect(item.lines.last == line)
        #expect(entries == [FeedEntry(item: item, line: line)])
    }

    @Test
    func apply_whenSinglePlaceLevelGoesDown_followsIt() throws {
        let red = RegionAlert.stub(level: .red, startedAt: FeedFixtures.date(0))
        let yellow = RegionAlert.stub(level: .yellow, startedAt: FeedFixtures.date(0))
        var sut = makeSUT(started: [red])

        _ = sut.apply([.alertStarted(yellow, previous: red)], now: FeedFixtures.date(300))

        guard case .alert(let group) = try #require(sut.items.values.first).content else {
            Issue.record("Expected an alert bubble")
            return
        }
        #expect(group.level == .yellow)
    }

    // MARK: - apply: stale and repeated alerts

    @Test
    func apply_whenAlertStartedOver24HoursAgo_createsNoBubble() {
        var sut = makeSUT()
        let alert = RegionAlert.stub(startedAt: FeedFixtures.date(0))

        let entries = sut.apply([.alertStarted(alert, previous: nil)], now: FeedFixtures.date(24 * 3_600 + 1))

        #expect(entries.isEmpty)
        #expect(sut.items.isEmpty)
    }

    @Test
    func apply_whenAlertStartsAgainAfterReconnect_doesNotDuplicate() throws {
        let alert = RegionAlert.stub(startedAt: FeedFixtures.date(0))
        var sut = makeSUT(started: [alert])

        let entries = sut.apply(
            [.alertStarted(alert, previous: nil), .alertStarted(alert, previous: alert)],
            now: FeedFixtures.date(600)
        )

        let item = try #require(sut.items.values.first)
        guard case .alert(let group) = item.content else {
            Issue.record("Expected an alert bubble")
            return
        }
        #expect(entries.isEmpty)
        #expect(sut.items.count == 1)
        #expect(group.places.count == 1)
        #expect(item.lines.count == 1)
    }
}

// MARK: - Helpers

private extension FeedBuilderAlertTests {

    /// A builder that already saw the `started` alerts declared, each at its own start.
    func makeSUT(started alerts: [RegionAlert] = []) -> FeedBuilder {
        var sut = FeedBuilder()
        for alert in alerts {
            _ = sut.apply([.alertStarted(alert, previous: nil)], now: alert.startedAt)
        }
        return sut
    }
}
