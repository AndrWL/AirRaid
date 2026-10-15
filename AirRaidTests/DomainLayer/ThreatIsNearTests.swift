//
//  ThreatIsNearTests.swift
//  AirRaidTests
//

import Testing
@testable import AirRaid

/// Tests for ``Threat/isNear(_:)``, for one place and for several: whether a threat turns red and sounds for a place.
///
/// Covers each position quality: a confirmed position inside the radius, an approximate one only when its
/// uncertainty fits the radius, and a target-only or area report never; and the forecast never counting.
@Suite
struct ThreatIsNearTests {

    // MARK: - isNear(_ place:)

    @Test
    func isNear_whenConfirmedPositionInsideRadius_returnsTrue() {
        let sut = makeSUT(distanceKm: 8, positionQuality: .confirmed)

        let isNear = sut.isNear(Constants.place)

        #expect(isNear)
    }

    @Test
    func isNear_whenConfirmedPositionOutsideRadius_returnsFalse() {
        let sut = makeSUT(distanceKm: 12, positionQuality: .confirmed)

        let isNear = sut.isNear(Constants.place)

        #expect(!isNear)
    }

    @Test
    func isNear_whenConfirmedPositionCarriesLargeUncertainty_stillCountsPosition() {
        let sut = makeSUT(distanceKm: 8, positionQuality: .confirmed, accuracyKm: 60)

        let isNear = sut.isNear(Constants.place)

        #expect(isNear)
    }

    @Test(arguments: [5.0, 10.0])
    func isNear_whenApproximatePositionInsideAndUncertaintyFitsRadius_returnsTrue(accuracyKm: Double) {
        let sut = makeSUT(distanceKm: 8, positionQuality: .approximate, accuracyKm: accuracyKm)

        let isNear = sut.isNear(Constants.place)

        #expect(isNear)
    }

    @Test
    func isNear_whenApproximatePositionInsideButUncertaintyExceedsRadius_returnsFalse() {
        let sut = makeSUT(distanceKm: 2, positionQuality: .approximate, accuracyKm: 62)

        let isNear = sut.isNear(Constants.place)

        #expect(!isNear)
    }

    @Test
    func isNear_whenApproximatePositionOutsideRadius_returnsFalse() {
        let sut = makeSUT(distanceKm: 12, positionQuality: .approximate, accuracyKm: 1)

        let isNear = sut.isNear(Constants.place)

        #expect(!isNear)
    }

    @Test(arguments: [ThreatPositionQuality.targetOnly, .area])
    func isNear_whenOnlyTargetOrAreaKnown_returnsFalseEvenOnThePlace(positionQuality: ThreatPositionQuality) {
        let sut = makeSUT(distanceKm: 0, positionQuality: positionQuality, accuracyKm: 0)

        let isNear = sut.isNear(Constants.place)

        #expect(!isNear)
    }

    @Test
    func isNear_whenNoPositionButTargetIsThePlace_returnsFalse() {
        let sut = Threat.stub(positionName: nil, targetName: "Біла Церква", targetCoordinate: Constants.place.coordinate)

        let isNear = sut.isNear(Constants.place)

        #expect(!isNear)
    }

    @Test
    func isNear_whenForecastWouldReachPlace_judgesOnlyReportedPosition() {
        let sut = Threat.stub(
            positionCoordinate: Constants.place.coordinate.moved(bearing: 0, distanceKm: 20),
            heading: 180,
            speedKmh: 600,
            movedAt: FeedFixtures.date(-600)
        )

        let isNear = sut.isNear(Constants.place)

        #expect(!isNear)
    }

    // MARK: - isNear(_ places:)

    @Test
    func isNear_whenAnyPlaceContainsThreat_returnsTrue() {
        let far = WatchedPlace.stub(id: "far", coordinate: MapFixtures.kyiv, radiusKm: 5)
        let sut = makeSUT(distanceKm: 8, positionQuality: .confirmed)

        let isNear = sut.isNear([far, Constants.place])

        #expect(isNear)
    }

    @Test
    func isNear_whenNoPlaceContainsThreat_returnsFalse() {
        let far = WatchedPlace.stub(id: "far", coordinate: MapFixtures.kyiv, radiusKm: 5)
        let sut = makeSUT(distanceKm: 8, positionQuality: .confirmed)

        let isNear = sut.isNear([far])

        #expect(!isNear)
    }

    @Test
    func isNear_whenNoPlaces_returnsFalse() {
        let sut = makeSUT(distanceKm: 0, positionQuality: .confirmed)

        let isNear = sut.isNear([WatchedPlace]())

        #expect(!isNear)
    }

    @Test
    func isNear_whenApproximateFitsOnlyWiderPlace_returnsTrue() {
        let wide = WatchedPlace.stub(id: "wide", coordinate: Constants.place.coordinate, radiusKm: 50)
        let sut = makeSUT(distanceKm: 8, positionQuality: .approximate, accuracyKm: 30)

        let isNear = sut.isNear([Constants.place, wide])

        #expect(isNear)
    }
}

// MARK: - Helpers

private extension ThreatIsNearTests {

    /// A threat `distanceKm` north of ``Constants/place``.
    func makeSUT(
        distanceKm: Double,
        positionQuality: ThreatPositionQuality,
        accuracyKm: Double = 5
    ) -> Threat {
        Threat.stub(
            positionCoordinate: Constants.place.coordinate.moved(bearing: 0, distanceKm: distanceKm),
            positionQuality: positionQuality,
            accuracyKm: accuracyKm
        )
    }
}

// MARK: - Constants

private enum Constants {
    /// The home, watched within 10 km.
    static let place = WatchedPlace.stub(coordinate: MapFixtures.bilaTserkva, radiusKm: 10)
}
