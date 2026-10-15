//
//  FeedItemEntityMapperTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``FeedItemEntityMapper``.
///
/// Covers a round trip of every line event and both contents, and names this build does not know.
@Suite
struct FeedItemEntityMapperTests {

    // MARK: - Round trip

    @Test
    func allEvents_whenListed_coverEveryEventFamily() {
        let families = Set(Constants.allEvents.map(\.family))

        #expect(families == Set(0...9))
    }

    @Test(arguments: Constants.allEvents)
    func map_whenLineEventRoundTrips_keepsIt(event: FeedLineEvent) throws {
        let item = FeedItem.stub(lines: [FeedLine(date: FeedFixtures.date(60), event: event)])

        let restored = try roundTrip(item)

        #expect(restored == item)
    }

    @Test
    func map_whenThreatBubbleRoundTrips_keepsEveryField() throws {
        let item = FeedItem.stub(
            updatedAt: FeedFixtures.date(300),
            isActive: false,
            priority: .critical,
            regionIDs: ["UA-32", "UA-18"],
            lines: Constants.allEvents.enumerated().map { FeedLine(date: FeedFixtures.date(Double($0.offset)), event: $0.element) },
            droppedLineCount: 3,
            content: .threat(FeedThreat(
                threatID: "t1",
                kind: .ballisticMissile,
                type: nil,
                count: 4,
                level: .high,
                regionID: "UA",
                regionName: "Україна",
                positionName: nil,
                targetName: "Київ",
                isCountryWide: true
            ))
        )

        let restored = try roundTrip(item)

        #expect(restored == item)
    }

    @Test
    func map_whenAlertBubbleRoundTrips_keepsEveryField() throws {
        let item = FeedItem.stub(
            id: "alert:UA-32:airRaid:0",
            priority: .high,
            content: .alert(.stub(
                kind: .artilleryShelling,
                level: .yellow,
                places: [
                    .stub(alertID: "a1", scope: .hromada, endedAt: FeedFixtures.date(600)),
                    .stub(alertID: "a2", name: "Київ", scope: .city, startedAt: FeedFixtures.date(30))
                ]
            ))
        )

        let restored = try roundTrip(item)

        #expect(restored == item)
    }

    @Test
    func map_whenAlertHasNoLevel_keepsNil() throws {
        let item = FeedItem.stub(content: .alert(.stub(level: nil)))

        let restored = try roundTrip(item)

        #expect(restored == item)
    }

    // MARK: - Unknown names

    @Test
    func map_whenThreatKindUnknown_dropsBubble() {
        let entity = FeedItemEntity.stub(threat: .stub(kind: "laser"))

        #expect(FeedItemEntityMapper.map(entity) == nil)
    }

    @Test
    func map_whenThreatLevelUnknown_dropsBubble() {
        let entity = FeedItemEntity.stub(threat: .stub(level: "certain"))

        #expect(FeedItemEntityMapper.map(entity) == nil)
    }

    @Test
    func map_whenAlertKindUnknown_dropsBubble() {
        let entity = FeedItemEntity.stub(threat: nil, alert: FeedAlertEntity(kind: "tsunami", level: nil, regionID: "UA-32", places: []))

        #expect(FeedItemEntityMapper.map(entity) == nil)
    }

    @Test
    func map_whenBubbleHasNoContent_dropsBubble() {
        let entity = FeedItemEntity.stub(threat: nil)

        #expect(FeedItemEntityMapper.map(entity) == nil)
    }

    @Test
    func map_whenThreatTypeUnknown_keepsBubbleWithoutType() throws {
        let entity = FeedItemEntity.stub(threat: .stub(type: "hypersonicGlider"))

        let item = try #require(FeedItemEntityMapper.map(entity))

        #expect(item.content == .threat(.stub(type: nil)))
    }

    @Test
    func map_whenUnknownLines_dropsOnlyThem() throws {
        let entity = FeedItemEntity.stub(lines: [
            FeedLineEntity(date: FeedFixtures.date(0), event: "threatTeleported"),
            FeedLineEntity(date: FeedFixtures.date(1), event: "threatCountChanged", number: 2),
            FeedLineEntity(date: FeedFixtures.date(2), event: "threatRefined", kind: "laser"),
            FeedLineEntity(date: FeedFixtures.date(3), event: "threatConfirmed", level: "certain"),
            FeedLineEntity(date: FeedFixtures.date(4), event: "alertLevelChanged", number: 7),
            FeedLineEntity(date: FeedFixtures.date(5), event: "threatAppeared")
        ])

        let item = try #require(FeedItemEntityMapper.map(entity))

        #expect(item.lines == [FeedLine(date: FeedFixtures.date(1), event: .threatCountChanged(2))])
    }

    @Test
    func map_whenCloseReasonUnknown_readsAsUnknown() throws {
        let entity = FeedItemEntity.stub(lines: [FeedLineEntity(date: FeedFixtures.date(0), event: "threatClosed", reason: "shotDown")])

        let item = try #require(FeedItemEntityMapper.map(entity))

        #expect(item.lines.map(\.event) == [.threatClosed(.unknown)])
    }

    @Test
    func map_whenPlaceScopeOrPriorityUnknown_fallsBack() throws {
        let entity = FeedItemEntity.stub(
            priority: 42,
            threat: nil,
            alert: FeedAlertEntity(
                kind: "airRaid",
                level: 9,
                regionID: "UA-32",
                places: [
                    FeedAlertPlaceEntity(
                        alertID: "a1",
                        name: "Бучанський район",
                        scope: "village",
                        startedAt: FeedFixtures.origin,
                        endedAt: nil
                    )
                ]
            )
        )

        let item = try #require(FeedItemEntityMapper.map(entity))

        #expect(item.priority == .normal)
        #expect(item.content == .alert(.stub(level: nil, places: [.stub(scope: .unknown)])))
    }
}

// MARK: - Helpers

private extension FeedItemEntityMapperTests {

    /// To the stored form, through JSON as on disk, and back.
    func roundTrip(_ item: FeedItem) throws -> FeedItem? {
        let data = try JSONEncoder().encode(FeedItemEntityMapper.map(item))
        return FeedItemEntityMapper.map(try JSONDecoder().decode(FeedItemEntity.self, from: data))
    }
}

private extension FeedItemEntity {

    static func stub(
        priority: Int = 1,
        lines: [FeedLineEntity] = [],
        threat: FeedThreatEntity? = .stub(),
        alert: FeedAlertEntity? = nil
    ) -> FeedItemEntity {
        FeedItemEntity(
            id: "threat:t1",
            createdAt: FeedFixtures.origin,
            updatedAt: FeedFixtures.origin,
            isActive: true,
            priority: priority,
            regionIDs: ["UA-32"],
            lines: lines,
            droppedLineCount: 0,
            threat: threat,
            alert: alert
        )
    }
}

private extension FeedThreatEntity {

    static func stub(
        kind: String = "drone",
        type: String? = "shahed",
        level: String = "medium"
    ) -> FeedThreatEntity {
        FeedThreatEntity(
            threatID: "t1",
            kind: kind,
            type: type,
            count: nil,
            level: level,
            regionID: "UA-32",
            regionName: "Київська область",
            positionName: "Біла Церква",
            targetName: nil,
            isCountryWide: false
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let allEvents: [FeedLineEvent] = [
        .threatAppeared(regionName: "Київська область", positionName: "Біла Церква", targetName: "Київ"),
        .threatAppeared(regionName: "Київська область", positionName: nil, targetName: nil),
        .threatRefined(kind: .drone, type: .jetDrone),
        .threatRefined(kind: .unknown, type: nil),
        .threatCountChanged(3),
        .threatConfirmed(level: .high, sourceCount: 4),
        .threatCrossedRegion(regionName: "Житомирська область"),
        .threatCourseChanged(targetName: "Фастів"),
        .threatClosed(.ended),
        .threatClosed(.cancelled),
        .threatClosed(.merged(survivorID: "t2")),
        .threatClosed(.merged(survivorID: nil)),
        .threatClosed(.unknown),
        .alertStarted(placeName: "Бучанський район"),
        .alertLevelChanged(.yellow),
        .alertLevelChanged(.red),
        .alertEnded(placeName: "Бучанський район", duration: 1_234.5)
    ]
}
