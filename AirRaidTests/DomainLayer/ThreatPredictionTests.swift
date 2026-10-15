//
//  ThreatPredictionTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``Threat/predictedCoordinate(at:)``, ``Threat/course`` and ``Threat/timeToTarget(at:)`` — the app's copy
/// of the backend's `predict()`.
///
/// Covers moving along the heading and toward the target (the target wins), the limits: no position, no speed, no
/// direction, before the last report, 15 minutes, ``Threat/expiresAt``, never past the target; and the time to the
/// target counting down by the same rules.
@Suite
struct ThreatPredictionTests {

    // MARK: - predictedCoordinate(at:): along the heading

    @Test
    func predictedCoordinate_whenHeadingOnly_movesAlongHeadingAtSpeed() throws {
        let sut = makeSUT(heading: 90)

        let predicted = try #require(sut.predictedCoordinate(at: FeedFixtures.date(10 * 60)))

        #expect(abs(Constants.start.distance(to: predicted) - 30) < Constants.toleranceKm)
        #expect(abs(Constants.start.initialBearing(to: predicted) - 90) < Constants.toleranceDegrees)
    }

    @Test
    func predictedCoordinate_whenAtLastReport_returnsPosition() throws {
        let sut = makeSUT(heading: 90)

        let predicted = try #require(sut.predictedCoordinate(at: FeedFixtures.origin))

        #expect(Constants.start.distance(to: predicted) < Constants.toleranceKm)
    }

    @Test
    func predictedCoordinate_whenBeforeLastReport_returnsPosition() throws {
        let sut = makeSUT(heading: 90)

        let predicted = try #require(sut.predictedCoordinate(at: FeedFixtures.date(-5 * 60)))

        #expect(Constants.start.distance(to: predicted) < Constants.toleranceKm)
    }

    @Test
    func predictedCoordinate_whenPastFifteenMinutes_stopsAtFifteen() throws {
        let sut = makeSUT(heading: 90, expiresAt: FeedFixtures.date(3_600))

        let atLimit = try #require(sut.predictedCoordinate(at: FeedFixtures.date(15 * 60)))
        let later = try #require(sut.predictedCoordinate(at: FeedFixtures.date(40 * 60)))

        #expect(later == atLimit)
        #expect(abs(Constants.start.distance(to: later) - 45) < Constants.toleranceKm)
    }

    @Test
    func predictedCoordinate_whenPastExpiry_stopsAtExpiry() throws {
        let sut = makeSUT(heading: 90, expiresAt: FeedFixtures.date(5 * 60))

        let atExpiry = try #require(sut.predictedCoordinate(at: FeedFixtures.date(5 * 60)))
        let later = try #require(sut.predictedCoordinate(at: FeedFixtures.date(10 * 60)))

        #expect(later == atExpiry)
        #expect(abs(Constants.start.distance(to: later) - 15) < Constants.toleranceKm)
    }

    @Test
    func predictedCoordinate_whenExpiredBeforeLastReport_staysAtPosition() throws {
        let sut = makeSUT(heading: 90, expiresAt: FeedFixtures.date(-60))

        let predicted = try #require(sut.predictedCoordinate(at: FeedFixtures.date(10 * 60)))

        #expect(Constants.start.distance(to: predicted) < Constants.toleranceKm)
    }

    // MARK: - predictedCoordinate(at:): toward the target

    @Test
    func predictedCoordinate_whenTargetKnown_movesTowardTarget() throws {
        let target = Constants.start.moved(bearing: 0, distanceKm: 60)
        let sut = makeSUT(target: target)

        let predicted = try #require(sut.predictedCoordinate(at: FeedFixtures.date(10 * 60)))

        #expect(abs(Constants.start.distance(to: predicted) - 30) < Constants.toleranceKm)
        #expect(abs(predicted.distance(to: target) - 30) < Constants.toleranceKm)
    }

    @Test
    func predictedCoordinate_whenTargetCloserThanTravel_stopsAtTarget() throws {
        let target = Constants.start.moved(bearing: 0, distanceKm: 10)
        let sut = makeSUT(target: target)

        let predicted = try #require(sut.predictedCoordinate(at: FeedFixtures.date(10 * 60)))

        #expect(predicted == target)
    }

    @Test
    func predictedCoordinate_whenTargetAndHeadingDisagree_followsTarget() throws {
        let target = Constants.start.moved(bearing: 0, distanceKm: 60)
        let sut = makeSUT(target: target, heading: 180)

        let predicted = try #require(sut.predictedCoordinate(at: FeedFixtures.date(10 * 60)))

        #expect(predicted.latitude > Constants.start.latitude)
        #expect(abs(predicted.distance(to: target) - 30) < Constants.toleranceKm)
    }

    // MARK: - predictedCoordinate(at:): not moved

    @Test
    func predictedCoordinate_whenNoPosition_returnsNil() {
        let sut = Threat.stub(positionName: nil, targetName: "Київ", targetCoordinate: MapFixtures.kyiv, heading: 0)

        let predicted = sut.predictedCoordinate(at: FeedFixtures.date(60))

        #expect(predicted == nil)
    }

    @Test(arguments: [0.0, -10.0])
    func predictedCoordinate_whenNoSpeed_returnsNil(speedKmh: Double) {
        let sut = makeSUT(heading: 90, speedKmh: speedKmh)

        let predicted = sut.predictedCoordinate(at: FeedFixtures.date(60))

        #expect(predicted == nil)
    }

    @Test
    func predictedCoordinate_whenNeitherTargetNorHeading_returnsNil() {
        let sut = makeSUT()

        let predicted = sut.predictedCoordinate(at: FeedFixtures.date(60))

        #expect(predicted == nil)
    }

    // MARK: - course

    @Test
    func course_whenTargetWest_returnsBearingInFullCircle() throws {
        let sut = makeSUT(target: Constants.start.moved(bearing: 270, distanceKm: 50))

        let course = try #require(sut.course)

        #expect(abs(course - 270) < Constants.toleranceDegrees)
    }

    @Test
    func course_whenTargetAndHeadingDisagree_returnsBearingToTarget() throws {
        let sut = makeSUT(target: Constants.start.moved(bearing: 45, distanceKm: 50), heading: 200)

        let course = try #require(sut.course)

        #expect(abs(course - 45) < Constants.toleranceDegrees)
    }

    @Test
    func course_whenTargetIsAtPosition_returnsHeading() {
        let sut = makeSUT(target: Constants.start, heading: 120)

        let course = sut.course

        #expect(course == 120)
    }

    @Test
    func course_whenNoTarget_returnsHeading() {
        let sut = makeSUT(heading: 120)

        let course = sut.course

        #expect(course == 120)
    }

    @Test
    func course_whenNeitherTargetNorHeading_returnsNil() {
        let sut = makeSUT()

        let course = sut.course

        #expect(course == nil)
    }

    // MARK: - timeToTarget(at:)

    @Test
    func timeToTarget_whenAtLastReport_returnsWholeFlight() throws {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 30))

        let time = try #require(sut.timeToTarget(at: FeedFixtures.origin))

        #expect(abs(time - 600) < Constants.toleranceSeconds)
    }

    @Test
    func timeToTarget_whenMinutesPassed_countsDown() throws {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 30))

        let time = try #require(sut.timeToTarget(at: FeedFixtures.date(4 * 60)))

        #expect(abs(time - 360) < Constants.toleranceSeconds)
    }

    @Test
    func timeToTarget_whenBeforeLastReport_returnsWholeFlight() throws {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 30))

        let time = try #require(sut.timeToTarget(at: FeedFixtures.date(-120)))

        #expect(abs(time - 600) < Constants.toleranceSeconds)
    }

    @Test
    func timeToTarget_whenForecastArrived_returnsZero() {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 10))

        let time = sut.timeToTarget(at: FeedFixtures.date(5 * 60))

        #expect(time == 0)
    }

    @Test
    func timeToTarget_whenExactlyFifteenMinutes_stillEstimates() {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 90), expiresAt: FeedFixtures.date(3_600))

        let time = sut.timeToTarget(at: FeedFixtures.date(15 * 60))

        #expect(time != nil)
    }

    @Test
    func timeToTarget_whenPastFifteenMinutes_returnsNil() {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 90), expiresAt: FeedFixtures.date(3_600))

        let time = sut.timeToTarget(at: FeedFixtures.date(15 * 60 + 1))

        #expect(time == nil)
    }

    @Test
    func timeToTarget_whenAtExpiry_returnsNil() {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 90), expiresAt: FeedFixtures.date(5 * 60))

        let time = sut.timeToTarget(at: FeedFixtures.date(5 * 60))

        #expect(time == nil)
    }

    @Test
    func timeToTarget_whenNoTarget_returnsNil() {
        let sut = makeSUT(heading: 0)

        let time = sut.timeToTarget(at: FeedFixtures.origin)

        #expect(time == nil)
    }

    @Test
    func timeToTarget_whenNoSpeed_returnsNil() {
        let sut = makeSUT(target: Constants.start.moved(bearing: 0, distanceKm: 30), speedKmh: 0)

        let time = sut.timeToTarget(at: FeedFixtures.origin)

        #expect(time == nil)
    }
}

// MARK: - Helpers

private extension ThreatPredictionTests {

    /// A threat at ``Constants/start`` at 180 km/h — 3 km a minute — that reached it at the fixtures' origin.
    func makeSUT(
        target: GeoCoordinate? = nil,
        heading: Double? = nil,
        speedKmh: Double = 180,
        expiresAt: Date = FeedFixtures.date(3_600)
    ) -> Threat {
        Threat.stub(
            targetName: target.map { _ in "Ціль" },
            positionCoordinate: Constants.start,
            targetCoordinate: target ?? Constants.start,
            heading: heading,
            speedKmh: speedKmh,
            movedAt: FeedFixtures.origin,
            expiresAt: expiresAt
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let start = MapFixtures.bilaTserkva
    static let toleranceKm = 0.001
    static let toleranceDegrees = 0.5
    static let toleranceSeconds = 0.01
}
