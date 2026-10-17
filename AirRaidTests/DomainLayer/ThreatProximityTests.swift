//
//  ThreatProximityTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``Threat/proximity(to:at:)`` and ``ThreatProximity/isWithinUncertainty``: the distance and arrival the
/// banners and widgets show.
///
/// Covers measuring from the forecast position, the uncertainty of a confirmed and an approximate position, and the
/// arrival only for a threat flying the user's way (within 30°) while its forecast is current.
@Suite
struct ThreatProximityTests {

    // MARK: - proximity(to:at:)

    @Test
    func proximity_whenNoPosition_returnsNil() {
        let sut = Threat.stub(positionName: nil, targetName: "Біла Церква", targetCoordinate: Constants.user, positionQuality: .targetOnly)

        let proximity = sut.proximity(to: Constants.user, at: FeedFixtures.origin)

        #expect(proximity == nil)
    }

    @Test
    func proximity_whenFlyingAtUser_measuresFromForecastAndEstimatesArrival() throws {
        let sut = makeSUT(heading: 180)

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.date(5 * 60)))

        #expect(abs(proximity.distanceKm - 15) < Constants.toleranceKm)
        #expect(proximity.uncertaintyKm == 0)
        let arrival = try #require(proximity.timeToArrival)
        #expect(abs(arrival - 300) < Constants.toleranceSeconds)
    }

    @Test(arguments: [155.0, 205.0])
    func proximity_whenCourseWithin30Degrees_estimatesArrival(heading: Double) {
        let sut = makeSUT(heading: heading)

        let proximity = sut.proximity(to: Constants.user, at: FeedFixtures.origin)

        #expect(proximity?.timeToArrival != nil)
    }

    @Test(arguments: [145.0, 215.0, 0.0, 90.0])
    func proximity_whenCourseTurnsAway_hasNoArrival(heading: Double) throws {
        let sut = makeSUT(heading: heading)

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.origin))

        #expect(abs(proximity.distanceKm - 30) < Constants.toleranceKm)
        #expect(proximity.timeToArrival == nil)
    }

    @Test
    func proximity_whenTargetIsUser_estimatesArrivalWithoutHeading() throws {
        let sut = makeSUT(target: Constants.user)

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.origin))

        let arrival = try #require(proximity.timeToArrival)
        #expect(abs(arrival - 600) < Constants.toleranceSeconds)
    }

    @Test
    func proximity_whenUserBeyondTarget_hasNoArrival() throws {
        let sut = makeSUT(target: Constants.user.moved(bearing: 0, distanceKm: 15))

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.origin))

        #expect(abs(proximity.distanceKm - 30) < Constants.toleranceKm)
        #expect(proximity.timeToArrival == nil)
    }

    @Test
    func proximity_whenUserJustBeyondTarget_estimatesArrival() throws {
        let sut = makeSUT(target: Constants.user.moved(bearing: 0, distanceKm: 5))

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.origin))

        #expect(proximity.timeToArrival != nil)
    }

    @Test
    func proximity_whenNotMoving_measuresFromPositionWithoutArrival() throws {
        let sut = makeSUT(heading: 180, speedKmh: 0)

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.date(5 * 60)))

        #expect(abs(proximity.distanceKm - 30) < Constants.toleranceKm)
        #expect(proximity.timeToArrival == nil)
    }

    @Test
    func proximity_whenForecastExpired_measuresFromLastForecastWithoutArrival() throws {
        let sut = makeSUT(heading: 180, expiresAt: FeedFixtures.date(5 * 60))

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.date(8 * 60)))

        #expect(abs(proximity.distanceKm - 15) < Constants.toleranceKm)
        #expect(proximity.timeToArrival == nil)
    }

    @Test
    func proximity_whenApproximate_reportsAccuracyAsUncertainty() throws {
        let sut = makeSUT(positionQuality: .approximate, accuracyKm: 40)

        let proximity = try #require(sut.proximity(to: Constants.user, at: FeedFixtures.origin))

        #expect(proximity.uncertaintyKm == 40)
        #expect(proximity.isWithinUncertainty)
    }

    // MARK: - isWithinUncertainty

    @Test(arguments: [
        (10.0, 20.0, true),
        (20.0, 20.0, false),
        (30.0, 20.0, false),
        (0.5, 0.0, false)
    ])
    func isWithinUncertainty_whenDistanceComparedToUncertainty_returnsExpected(
        distanceKm: Double,
        uncertaintyKm: Double,
        expected: Bool
    ) {
        let sut = ThreatProximity(distanceKm: distanceKm, uncertaintyKm: uncertaintyKm, timeToArrival: nil)

        #expect(sut.isWithinUncertainty == expected)
    }
}

// MARK: - Helpers

private extension ThreatProximityTests {

    /// A threat 30 km due north of ``Constants/user`` at 180 km/h — 3 km a minute — reported at the fixtures' origin.
    func makeSUT(
        target: GeoCoordinate? = nil,
        positionQuality: ThreatPositionQuality = .confirmed,
        accuracyKm: Double = 5,
        heading: Double? = nil,
        speedKmh: Double = 180,
        expiresAt: Date = FeedFixtures.date(3_600)
    ) -> Threat {
        let position = Constants.user.moved(bearing: 0, distanceKm: 30)
        return Threat.stub(
            targetName: target.map { _ in "Ціль" },
            positionCoordinate: position,
            targetCoordinate: target ?? position,
            positionQuality: positionQuality,
            accuracyKm: accuracyKm,
            heading: heading,
            speedKmh: speedKmh,
            movedAt: FeedFixtures.origin,
            expiresAt: expiresAt
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let user = MapFixtures.bilaTserkva
    static let toleranceKm = 0.001
    static let toleranceSeconds = 0.01
}
