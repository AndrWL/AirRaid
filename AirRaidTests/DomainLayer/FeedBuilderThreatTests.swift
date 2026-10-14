//
//  FeedBuilderThreatTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``FeedBuilder/apply(_:now:)`` with threat events.
///
/// Covers the first line of a track, which reports add lines and which do not, throttling, and closing: merged,
/// ended, cancelled, and a closed track that comes back.
@Suite
struct FeedBuilderThreatTests {

    // MARK: - apply: a new threat

    @Test
    func apply_whenThreatIsNew_createsOneBubbleWithAppearedLineAtFirstSeen() throws {
        var sut = makeSUT()
        let threat = Threat.stub(targetName: "Київ", firstSeenAt: FeedFixtures.date(0), updatedAt: FeedFixtures.date(60))

        let entries = sut.apply([.threatUpdated(threat, previous: nil)], now: FeedFixtures.date(120))

        let item = try #require(sut.items[Constants.itemID])
        let line = FeedLine(
            date: FeedFixtures.date(0),
            event: .threatAppeared(regionName: "Київська область", positionName: "Біла Церква", targetName: "Київ")
        )
        #expect(sut.items.count == 1)
        #expect(item.lines == [line])
        #expect(item.isActive)
        #expect(item.createdAt == FeedFixtures.date(0))
        #expect(item.updatedAt == FeedFixtures.date(60))
        #expect(item.regionIDs == ["UA-32"])
        #expect(entries == [FeedEntry(item: item, line: line)])
    }

    @Test
    func apply_whenThreatIsCountryWide_leavesRegionsEmpty() throws {
        var sut = makeSUT()
        let threat = Threat.stub(kind: .ballisticMissile, type: .ballisticMissile, regionID: "UA", regionName: "Україна")

        _ = sut.apply([.threatUpdated(threat, previous: nil)], now: FeedFixtures.date(0))

        let item = try #require(sut.items[Constants.itemID])
        #expect(item.regionIDs.isEmpty)
        #expect(item.priority == .critical)
    }

    // MARK: - apply: further reports

    @Test
    func apply_whenThreatOnlyMoves_addsNoLineAndUpdatesHeader() throws {
        var sut = makeSUT(reported: .stub())
        let moved = Threat.stub(positionName: "Фастів", updatedAt: FeedFixtures.date(60))

        let entries = sut.apply([.threatUpdated(moved, previous: .stub())], now: FeedFixtures.date(60))

        let item = try #require(sut.items[Constants.itemID])
        #expect(entries.isEmpty)
        #expect(item.lines.count == 1)
        #expect(item.updatedAt == FeedFixtures.date(60))
        guard case .threat(let threat) = item.content else {
            Issue.record("Expected a threat bubble")
            return
        }
        #expect(threat.positionName == "Фастів")
    }

    @Test(arguments: SignificantChange.all)
    func apply_whenSignificantChange_addsMatchingLine(change: SignificantChange) throws {
        var sut = makeSUT(reported: .stub())

        let entries = sut.apply([.threatUpdated(change.threat, previous: .stub())], now: FeedFixtures.date(60))

        let item = try #require(sut.items[Constants.itemID])
        let expected = FeedLine(date: FeedFixtures.date(60), event: change.event)
        #expect(Array(item.lines.dropFirst()) == [expected])
        #expect(entries.map(\.line) == [expected])
    }

    @Test
    func apply_whenConfidenceGoesDown_addsNoLine() throws {
        var sut = makeSUT(reported: .stub(level: .high))
        let weaker = Threat.stub(level: .medium, updatedAt: FeedFixtures.date(60))

        let entries = sut.apply([.threatUpdated(weaker, previous: nil)], now: FeedFixtures.date(60))

        #expect(entries.isEmpty)
        #expect(try #require(sut.items[Constants.itemID]).lines.count == 1)
    }

    @Test
    func apply_whenThreatBecomesCountryWide_addsNoCrossedRegionLine() throws {
        var sut = makeSUT(reported: .stub())
        let countryWide = Threat.stub(regionID: "UA", regionName: "Україна", updatedAt: FeedFixtures.date(60))

        let entries = sut.apply([.threatUpdated(countryWide, previous: nil)], now: FeedFixtures.date(60))

        let item = try #require(sut.items[Constants.itemID])
        #expect(entries.isEmpty)
        #expect(item.regionIDs == ["UA-32"])
    }

    @Test
    func apply_whenSeveralChangesInOneReport_addsOneLinePerChange() throws {
        var sut = makeSUT(reported: .stub())
        let changed = Threat.stub(type: .jetDrone, count: 3, updatedAt: FeedFixtures.date(60))

        let entries = sut.apply([.threatUpdated(changed, previous: nil)], now: FeedFixtures.date(60))

        #expect(entries.map(\.line.event) == [.threatRefined(kind: .drone, type: .jetDrone), .threatCountChanged(3)])
    }

    @Test
    func apply_whenBatchAddsSeveralLines_returnsEachWithBubbleAfterWholeBatch() throws {
        var sut = makeSUT()
        let events: [AirSituationEvent] = [
            .threatUpdated(.stub(), previous: nil),
            .threatUpdated(.stub(count: 5, updatedAt: FeedFixtures.date(30)), previous: .stub())
        ]

        let entries = sut.apply(events, now: FeedFixtures.date(30))

        let item = try #require(sut.items[Constants.itemID])
        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.item == item })
        #expect(item.lines.count == 2)
    }

    // MARK: - apply: throttling

    @Test
    func apply_whenSameKindOfLineWithinThrottleInterval_dropsIt() throws {
        var sut = makeSUT(reported: .stub())
        _ = sut.apply([.threatUpdated(.stub(type: .jetDrone, updatedAt: FeedFixtures.date(10)), previous: nil)], now: FeedFixtures.date(10))

        let entries = sut.apply(
            [.threatUpdated(.stub(type: .drone, updatedAt: FeedFixtures.date(10 + 179)), previous: nil)],
            now: FeedFixtures.date(10 + 179)
        )

        let item = try #require(sut.items[Constants.itemID])
        #expect(entries.isEmpty)
        #expect(item.lines.map(\.event) == [Constants.appeared, .threatRefined(kind: .drone, type: .jetDrone)])
        guard case .threat(let threat) = item.content else {
            Issue.record("Expected a threat bubble")
            return
        }
        #expect(threat.type == .drone)
    }

    @Test
    func apply_whenSameKindOfLineAfterThrottleInterval_addsIt() throws {
        var sut = makeSUT(reported: .stub())
        _ = sut.apply([.threatUpdated(.stub(type: .jetDrone, updatedAt: FeedFixtures.date(10)), previous: nil)], now: FeedFixtures.date(10))

        let entries = sut.apply(
            [.threatUpdated(.stub(type: .drone, updatedAt: FeedFixtures.date(10 + 180)), previous: nil)],
            now: FeedFixtures.date(10 + 180)
        )

        #expect(entries.map(\.line.event) == [.threatRefined(kind: .drone, type: .drone)])
    }

    @Test
    func apply_whenOtherKindOfLineWithinThrottleInterval_addsIt() throws {
        var sut = makeSUT(reported: .stub())
        _ = sut.apply([.threatUpdated(.stub(type: .jetDrone, updatedAt: FeedFixtures.date(10)), previous: nil)], now: FeedFixtures.date(10))

        let entries = sut.apply(
            [.threatUpdated(.stub(type: .jetDrone, count: 2, updatedAt: FeedFixtures.date(20)), previous: nil)],
            now: FeedFixtures.date(20)
        )

        #expect(entries.map(\.line.event) == [.threatCountChanged(2)])
    }

    // MARK: - apply: closing

    @Test
    func apply_whenThreatMerged_removesBubble() {
        var sut = makeSUT(reported: .stub())

        let entries = sut.apply(
            [.threatClosed(.stub(), reason: .merged(survivorID: "t2"), at: FeedFixtures.date(60))],
            now: FeedFixtures.date(60)
        )

        #expect(entries.isEmpty)
        #expect(sut.items.isEmpty)
    }

    @Test(arguments: [ThreatCloseReason.ended, .cancelled])
    func apply_whenThreatClosed_closesBubbleWithClosedLine(reason: ThreatCloseReason) throws {
        var sut = makeSUT(reported: .stub())

        let entries = sut.apply([.threatClosed(.stub(), reason: reason, at: FeedFixtures.date(60))], now: FeedFixtures.date(60))

        let item = try #require(sut.items[Constants.itemID])
        let line = FeedLine(date: FeedFixtures.date(60), event: .threatClosed(reason))
        #expect(!item.isActive)
        #expect(item.lines.last == line)
        #expect(item.updatedAt == FeedFixtures.date(60))
        #expect(entries == [FeedEntry(item: item, line: line)])
    }

    @Test
    func apply_whenClosedThreatClosesAgain_addsNothing() throws {
        var sut = makeSUT(reported: .stub())
        _ = sut.apply([.threatClosed(.stub(), reason: .ended, at: FeedFixtures.date(60))], now: FeedFixtures.date(60))

        let entries = sut.apply([.threatClosed(.stub(), reason: .ended, at: FeedFixtures.date(90))], now: FeedFixtures.date(90))

        #expect(entries.isEmpty)
        #expect(try #require(sut.items[Constants.itemID]).lines.count == 2)
    }

    @Test
    func apply_whenUnknownThreatCloses_addsNothing() {
        var sut = makeSUT()

        let entries = sut.apply([.threatClosed(.stub(), reason: .ended, at: FeedFixtures.date(60))], now: FeedFixtures.date(60))

        #expect(entries.isEmpty)
        #expect(sut.items.isEmpty)
    }

    @Test
    func apply_whenClosedThreatIsReportedAgain_reopensSameBubble() throws {
        var sut = makeSUT(reported: .stub())
        _ = sut.apply([.threatClosed(.stub(), reason: .ended, at: FeedFixtures.date(60))], now: FeedFixtures.date(60))

        let entries = sut.apply(
            [.threatUpdated(.stub(count: 2, updatedAt: FeedFixtures.date(300)), previous: nil)],
            now: FeedFixtures.date(300)
        )

        let item = try #require(sut.items[Constants.itemID])
        #expect(sut.items.count == 1)
        #expect(item.isActive)
        #expect(item.lines.map(\.event) == [Constants.appeared, .threatClosed(.ended), .threatCountChanged(2)])
        #expect(entries.map(\.line.event) == [.threatCountChanged(2)])
    }
}

// MARK: - SignificantChange

/// One report that changes the threat in a way a person cares about, and the line it should add.
struct SignificantChange: Sendable, CustomTestStringConvertible {

    let name: String
    let threat: Threat
    let event: FeedLineEvent

    var testDescription: String { name }

    static let all: [SignificantChange] = [
        SignificantChange(
            name: "type",
            threat: .stub(type: .jetDrone, updatedAt: FeedFixtures.date(60)),
            event: .threatRefined(kind: .drone, type: .jetDrone)
        ),
        SignificantChange(
            name: "kind",
            threat: .stub(kind: .missile, type: .cruiseMissile, updatedAt: FeedFixtures.date(60)),
            event: .threatRefined(kind: .missile, type: .cruiseMissile)
        ),
        SignificantChange(
            name: "count",
            threat: .stub(count: 4, updatedAt: FeedFixtures.date(60)),
            event: .threatCountChanged(4)
        ),
        SignificantChange(
            name: "confidence",
            threat: .stub(level: .high, sourceCount: 5, updatedAt: FeedFixtures.date(60)),
            event: .threatConfirmed(level: .high, sourceCount: 5)
        ),
        SignificantChange(
            name: "oblast",
            threat: .stub(regionID: "UA-18", regionName: "Житомирська область", updatedAt: FeedFixtures.date(60)),
            event: .threatCrossedRegion(regionName: "Житомирська область")
        ),
        SignificantChange(
            name: "target",
            threat: .stub(targetName: "Фастів", updatedAt: FeedFixtures.date(60)),
            event: .threatCourseChanged(targetName: "Фастів")
        )
    ]
}

// MARK: - Helpers

private extension FeedBuilderThreatTests {

    /// A builder that already saw `reported`, if given.
    func makeSUT(reported threat: Threat? = nil) -> FeedBuilder {
        var sut = FeedBuilder()
        if let threat {
            _ = sut.apply([.threatUpdated(threat, previous: nil)], now: threat.updatedAt)
        }
        return sut
    }
}

// MARK: - Constants

private enum Constants {
    static let itemID = "threat:t1"
    static let appeared = FeedLineEvent.threatAppeared(regionName: "Київська область", positionName: "Біла Церква", targetName: nil)
}
