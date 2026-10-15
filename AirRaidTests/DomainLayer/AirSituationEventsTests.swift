//
//  AirSituationEventsTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``AirSituation/events(since:at:)``.
///
/// Covers new, changed, unchanged and gone threats and alerts, and the order of the events.
@Suite
struct AirSituationEventsTests {

    // MARK: - events(since:at:)

    @Test
    func events_whenNothingChanged_returnsNothing() {
        let sut = makeSUT()

        let events = sut.events(since: makeSUT(), at: FeedFixtures.date(600))

        #expect(events.isEmpty)
    }

    @Test
    func events_whenThreatsChange_closesGoneThenUpdatesInFirstSeenOrder() {
        let kept = Threat.stub(id: "kept")
        let gone = Threat.stub(id: "gone")
        let changed = Threat.stub(id: "changed", firstSeenAt: FeedFixtures.date(20))
        let changedNow = Threat.stub(id: "changed", count: 2, firstSeenAt: FeedFixtures.date(20), updatedAt: FeedFixtures.date(500))
        let new = Threat.stub(id: "new", firstSeenAt: FeedFixtures.date(10))
        let previous = makeSUT(threats: [kept, gone, changed])
        let sut = makeSUT(threats: [changedNow, kept, new])

        let events = sut.events(since: previous, at: FeedFixtures.date(600))

        #expect(events == [
            .threatClosed(gone, reason: .unknown, at: FeedFixtures.date(600)),
            .threatUpdated(new, previous: nil),
            .threatUpdated(changedNow, previous: changed)
        ])
    }

    @Test
    func events_whenAlertsChange_endsGoneThenStartsInStartOrder() {
        let kept = RegionAlert.stub(id: "kept")
        let gone = RegionAlert.stub(id: "gone")
        let changed = RegionAlert.stub(id: "changed", level: .yellow, startedAt: FeedFixtures.date(20))
        let changedNow = RegionAlert.stub(id: "changed", level: .red, startedAt: FeedFixtures.date(20))
        let new = RegionAlert.stub(id: "new", startedAt: FeedFixtures.date(10))
        let previous = makeSUT(alerts: [kept, gone, changed])
        let sut = makeSUT(alerts: [changedNow, kept, new])

        let events = sut.events(since: previous, at: FeedFixtures.date(600))

        #expect(events == [
            .alertEnded(gone, at: FeedFixtures.date(600)),
            .alertStarted(new, previous: nil),
            .alertStarted(changedNow, previous: changed)
        ])
    }

    @Test
    func events_whenThreatsAndAlertsChange_putsThreatsFirst() {
        let previous = makeSUT(alerts: [.stub(id: "gone")], threats: [.stub(id: "gone")])
        let sut = makeSUT(alerts: [.stub(id: "new")], threats: [.stub(id: "new")])

        let events = sut.events(since: previous, at: FeedFixtures.date(600))

        #expect(events == [
            .threatClosed(.stub(id: "gone"), reason: .unknown, at: FeedFixtures.date(600)),
            .threatUpdated(.stub(id: "new"), previous: nil),
            .alertEnded(.stub(id: "gone"), at: FeedFixtures.date(600)),
            .alertStarted(.stub(id: "new"), previous: nil)
        ])
    }

    @Test
    func events_whenSinceEmpty_startsEverything() {
        let sut = makeSUT(alerts: [.stub()], threats: [.stub()])

        let events = sut.events(since: .empty, at: FeedFixtures.date(600))

        #expect(events == [.threatUpdated(.stub(), previous: nil), .alertStarted(.stub(), previous: nil)])
    }
}

// MARK: - Helpers

private extension AirSituationEventsTests {

    func makeSUT(
        alerts: [RegionAlert] = [.stub()],
        threats: [Threat] = [.stub()]
    ) -> AirSituation {
        AirSituation(alerts: alerts, threats: threats)
    }
}
