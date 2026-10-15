//
//  ThreatPlacementTests.swift
//  AirRaidTests
//

import Testing
@testable import AirRaid

/// Tests for ``Threat/markerCoordinate`` and ``Threat/markerCoordinate(coverage:districts:)``: where a threat's pin
/// goes.
///
/// Covers the position, target and region-center fallbacks, a country-wide report having no pin, and an area-only
/// report moved into the alerted raion of a partly alerted oblast — whole raions first, then the nearest to the
/// center, never a raion of another oblast, and inside a crescent-shaped raion.
@Suite
struct ThreatPlacementTests {

    // MARK: - markerCoordinate

    @Test
    func markerCoordinate_whenPositionKnown_returnsPosition() {
        let sut = Threat.stub(targetName: "Київ", positionCoordinate: Constants.west, targetCoordinate: MapFixtures.kyiv)

        #expect(sut.markerCoordinate == Constants.west)
    }

    @Test
    func markerCoordinate_whenOnlyTargetKnown_returnsTarget() {
        let sut = Threat.stub(positionName: nil, targetName: "Київ", targetCoordinate: MapFixtures.kyiv)

        #expect(sut.markerCoordinate == MapFixtures.kyiv)
    }

    @Test
    func markerCoordinate_whenOnlyAreaKnown_returnsRegionCenter() {
        let sut = makeSUT()

        #expect(sut.markerCoordinate == Constants.center)
    }

    @Test
    func markerCoordinate_whenCountryWide_returnsNil() {
        let sut = makeSUT(regionID: ThreatArea.countryWideRegionID)

        #expect(sut.markerCoordinate == nil)
    }

    // MARK: - markerCoordinate(coverage:districts:)

    @Test
    func markerCoordinateWithCoverage_whenPositionKnown_ignoresAlerts() {
        let sut = Threat.stub(positionCoordinate: Constants.west)
        let coverage = makeCoverage(districts: [Constants.eastKey: .whole])

        let marker = sut.markerCoordinate(coverage: coverage, districts: Constants.raions)

        #expect(marker == Constants.west)
    }

    @Test
    func markerCoordinateWithCoverage_whenTargetKnown_ignoresAlerts() {
        let sut = Threat.stub(positionName: nil, targetName: "Київ", targetCoordinate: MapFixtures.kyiv)
        let coverage = makeCoverage(districts: [Constants.eastKey: .whole])

        let marker = sut.markerCoordinate(coverage: coverage, districts: Constants.raions)

        #expect(marker == MapFixtures.kyiv)
    }

    @Test
    func markerCoordinateWithCoverage_whenCountryWide_returnsNil() {
        let sut = makeSUT(regionID: ThreatArea.countryWideRegionID)

        let marker = sut.markerCoordinate(coverage: makeCoverage(regions: ["UA": .red]), districts: Constants.raions)

        #expect(marker == nil)
    }

    @Test
    func markerCoordinateWithCoverage_whenWholeOblastAlerted_keepsCenter() {
        let sut = makeSUT()
        let coverage = makeCoverage(regions: ["UA-32": .red], districts: [Constants.eastKey: .whole])

        let marker = sut.markerCoordinate(coverage: coverage, districts: Constants.raions)

        #expect(marker == Constants.center)
    }

    @Test
    func markerCoordinateWithCoverage_whenNoRaionAlerted_keepsCenter() {
        let sut = makeSUT()

        let marker = sut.markerCoordinate(coverage: .none, districts: Constants.raions)

        #expect(marker == Constants.center)
    }

    @Test(arguments: [RegionAlertExtent.whole, .partial])
    func markerCoordinateWithCoverage_whenOneRaionAlerted_movesIntoIt(extent: RegionAlertExtent) {
        let sut = makeSUT()

        let marker = sut.markerCoordinate(coverage: makeCoverage(districts: [Constants.eastKey: extent]), districts: Constants.raions)

        #expect(isClose(marker, GeoCoordinate(latitude: 50, longitude: 30.5)))
    }

    @Test
    func markerCoordinateWithCoverage_whenWholeAndNearerPartialAlerted_prefersWhole() {
        let sut = makeSUT()
        let coverage = makeCoverage(districts: [Constants.eastKey: .partial, Constants.farKey: .whole])

        let marker = sut.markerCoordinate(coverage: coverage, districts: Constants.raions)

        #expect(isClose(marker, GeoCoordinate(latitude: 50, longitude: 32)))
    }

    @Test
    func markerCoordinateWithCoverage_whenSeveralWholeAlerted_takesNearestToCenter() {
        let sut = makeSUT()
        let coverage = makeCoverage(districts: [Constants.farKey: .whole, Constants.eastKey: .whole])

        let marker = sut.markerCoordinate(coverage: coverage, districts: Constants.raions)

        #expect(isClose(marker, GeoCoordinate(latitude: 50, longitude: 30.5)))
    }

    @Test
    func markerCoordinateWithCoverage_whenOnlyNamesakeInOtherOblastAlerted_keepsCenter() {
        let sut = makeSUT()
        let namesake = DistrictBoundary.stub(regionID: "UA-05", name: "Обухівський", polygons: [
            MapFixtures.rectangle(south: 48, west: 28, north: 49, east: 29)
        ])
        let coverage = makeCoverage(districts: [namesake.key: .whole])

        let marker = sut.markerCoordinate(coverage: coverage, districts: Constants.raions + [namesake])

        #expect(marker == Constants.center)
    }

    @Test
    func markerCoordinateWithCoverage_whenAlertedRaionHasNoOutline_keepsCenter() {
        let sut = makeSUT()
        let coverage = makeCoverage(districts: [DistrictKey(regionID: "UA-32", name: "Невідомий"): .whole])

        let marker = sut.markerCoordinate(coverage: coverage, districts: Constants.raions)

        #expect(marker == Constants.center)
    }

    @Test
    func markerCoordinateWithCoverage_whenRaionIsCrescent_putsPinInsideItsWidestStretch() throws {
        // A «U» open to the north, its eastern arm twice as wide as the western: the centroid falls in the gap.
        let crescent = DistrictBoundary.stub(name: "Підковоподібний", polygons: [GeoPolygon(
            exterior: [
                GeoCoordinate(latitude: 49, longitude: 29),
                GeoCoordinate(latitude: 49, longitude: 31),
                GeoCoordinate(latitude: 51, longitude: 31),
                GeoCoordinate(latitude: 51, longitude: 30.6),
                GeoCoordinate(latitude: 49.2, longitude: 30.6),
                GeoCoordinate(latitude: 49.2, longitude: 29.2),
                GeoCoordinate(latitude: 51, longitude: 29.2),
                GeoCoordinate(latitude: 51, longitude: 29)
            ],
            holes: []
        )])
        let sut = makeSUT()

        let marker = try #require(sut.markerCoordinate(coverage: makeCoverage(districts: [crescent.key: .whole]), districts: [crescent]))

        #expect(crescent.polygons[0].contains(marker))
        #expect(abs(marker.longitude - 30.8) < 1e-9)
    }
}

// MARK: - Helpers

private extension ThreatPlacementTests {

    /// An area-only report in Kyiv Oblast, its pin at the oblast's center.
    func makeSUT(regionID: String = "UA-32") -> Threat {
        Threat.stub(
            regionID: regionID,
            positionName: nil,
            areaCenter: Constants.center,
            positionQuality: .area
        )
    }

    func makeCoverage(
        regions: [String: RegionAlertLevel] = [:],
        districts: [DistrictKey: RegionAlertExtent] = [:]
    ) -> AirRaidCoverage {
        AirRaidCoverage(
            regions: regions,
            districts: districts.mapValues { RegionAlertCoverage(extent: $0, level: .red) }
        )
    }

    /// Centroids are computed, so compare within a hair rather than bit for bit.
    func isClose(
        _ coordinate: GeoCoordinate?,
        _ expected: GeoCoordinate
    ) -> Bool {
        guard let coordinate else { return false }
        return abs(coordinate.latitude - expected.latitude) < 1e-9 && abs(coordinate.longitude - expected.longitude) < 1e-9
    }
}

// MARK: - Constants

private enum Constants {
    /// The oblast's center; the raions are squares around (50, 29.5), (50, 30.5) and (50, 32).
    static let center = GeoCoordinate(latitude: 50, longitude: 30)
    static let west = GeoCoordinate(latitude: 50, longitude: 29.5)
    static let eastKey = DistrictKey(regionID: "UA-32", name: "Обухівський")
    static let farKey = DistrictKey(regionID: "UA-32", name: "Бориспільський")
    static let raions = [
        DistrictBoundary.stub(name: "Бучанський", polygons: [MapFixtures.square(center: west, halfSize: 0.5)]),
        DistrictBoundary.stub(name: eastKey.name, polygons: [
            MapFixtures.square(center: GeoCoordinate(latitude: 50, longitude: 30.5), halfSize: 0.5)
        ]),
        DistrictBoundary.stub(name: farKey.name, polygons: [
            MapFixtures.square(center: GeoCoordinate(latitude: 50, longitude: 32), halfSize: 0.5)
        ])
    ]
}
