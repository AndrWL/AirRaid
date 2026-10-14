//
//  FeedBuilderReconcileTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``FeedBuilder/reconcile(with:now:)`` and ``FeedBuilder/prune(endedBefore:)``.
///
/// Covers closing bubbles that are gone from the situation and forgetting old ended bubbles.
@Suite
struct FeedBuilderReconcileTests {

    // MARK: - reconcile

    @Test
    func reconcile_whenThreatMissingFromSituation_closesItsBubble() throws {
        var sut = makeSUT(items: [.stub(id: "threat:t1"), .stub(id: "threat:t2", content: .threat(.stub(threatID: "t2")))])

        sut.reconcile(with: AirSituation(alerts: [], threats: [.stub(id: "t2")]), now: FeedFixtures.date(600))

        let closed = try #require(sut.items["threat:t1"])
        let kept = try #require(sut.items["threat:t2"])
        #expect(!closed.isActive)
        #expect(closed.lines.last == FeedLine(date: FeedFixtures.date(600), event: .threatClosed(.unknown)))
        #expect(kept.isActive)
        #expect(kept.lines.isEmpty)
    }

    @Test
    func reconcile_whenOneAlertOfGroupMissing_endsThatPlaceOnly() throws {
        var sut = makeSUT(items: [Constants.alertItem])

        sut.reconcile(with: AirSituation(alerts: [.stub(id: "a2")], threats: []), now: FeedFixtures.date(600))

        let item = try #require(sut.items[Constants.alertItem.id])
        guard case .alert(let group) = item.content else {
            Issue.record("Expected an alert bubble")
            return
        }
        #expect(item.isActive)
        #expect(group.places.map(\.endedAt) == [FeedFixtures.date(600), nil])
        #expect(item.updatedAt == FeedFixtures.date(600))
        #expect(item.lines.isEmpty)
    }

    @Test
    func reconcile_whenAllAlertsOfGroupMissing_closesBubble() throws {
        var sut = makeSUT(items: [Constants.alertItem])

        sut.reconcile(with: .empty, now: FeedFixtures.date(600))

        #expect(try !#require(sut.items[Constants.alertItem.id]).isActive)
    }

    @Test
    func reconcile_whenEverythingStillInSituation_changesNothing() {
        let items: [FeedItem] = [.stub(id: "threat:t1"), Constants.alertItem]
        var sut = makeSUT(items: items)

        sut.reconcile(
            with: AirSituation(alerts: [.stub(id: "a1"), .stub(id: "a2")], threats: [.stub(id: "t1")]),
            now: FeedFixtures.date(600)
        )

        #expect(sut.items == makeSUT(items: items).items)
    }

    @Test
    func reconcile_whenBubbleAlreadyEnded_leavesItAlone() {
        let ended = FeedItem.stub(id: "threat:t1", isActive: false)
        var sut = makeSUT(items: [ended])

        sut.reconcile(with: .empty, now: FeedFixtures.date(600))

        #expect(sut.items["threat:t1"] == ended)
    }

    // MARK: - prune

    @Test
    func prune_whenBubbleEndedBeforeDate_dropsIt() {
        var sut = makeSUT(items: [
            .stub(id: "old-ended", updatedAt: FeedFixtures.date(0), isActive: false),
            .stub(id: "recent-ended", updatedAt: FeedFixtures.date(1_000), isActive: false),
            .stub(id: "old-active", updatedAt: FeedFixtures.date(0), isActive: true)
        ])

        sut.prune(endedBefore: FeedFixtures.date(1_000))

        #expect(Set(sut.items.keys) == ["recent-ended", "old-active"])
    }
}

// MARK: - Helpers

private extension FeedBuilderReconcileTests {

    func makeSUT(items: [FeedItem] = []) -> FeedBuilder {
        FeedBuilder(items: items)
    }
}

// MARK: - Constants

private enum Constants {
    static let alertItem = FeedItem.stub(
        id: "alert:UA-32:airRaid:0",
        content: .alert(.stub(places: [.stub(alertID: "a1"), .stub(alertID: "a2", name: "Броварський район")]))
    )
}
