//
//  HomeStatusFactoryTests.swift
//  AirRaidTests
//

import Foundation
import HomeStatusKit
import Testing
@testable import AirRaid

/// Tests for ``HomeStatusFactory/make(place:situation:regions:districts:now:)``: what the widgets and the Live
/// Activity say about the home.
///
/// Covers the place's name and kind, its oblast, the alert at its point (by raion, Kyiv apart from its oblast,
/// Sevastopol under Crimea), the nearest threat inside the radius by the map's rule with its wording and arrival, and
/// the closest one farther out while the radius is clear.
@MainActor
@Suite
struct HomeStatusFactoryTests {

    // MARK: - Place

    @Test
    func make_whenAddressKnown_namesPlaceByLocality() {
        let place = WatchedPlace.stub(coordinate: Constants.home, radiusKm: 10, address: PlaceAddress(locality: "Ірпінь", street: nil))

        let status = makeSUT(place: place)

        #expect(status.placeKind == .home)
        #expect(status.placeName == "Ірпінь")
        #expect(status.regionName == "Київська область")
        #expect(status.radiusKm == 10)
        #expect(status.miniMap != nil)
    }

    @Test(arguments: [
        (WatchedPlaceKind.home, StatusPlaceKind.home, "Дім"),
        (.currentLocation, .currentLocation, "Моя геолокація"),
        (.custom, .home, "Місце")
    ])
    func make_whenAddressUnknown_namesPlaceByKind(kind: WatchedPlaceKind, expectedKind: StatusPlaceKind, expectedName: String) {
        let status = makeSUT(place: .stub(kind: kind, coordinate: Constants.home))

        #expect(status.placeKind == expectedKind)
        #expect(status.placeName == expectedName)
    }

    @Test
    func make_whenOutsideEveryOblast_hasNoRegionAlertOrMiniMap() {
        let situation = AirSituation(alerts: [.stub(scope: .oblast)], threats: [])

        let status = makeSUT(place: .stub(coordinate: GeoCoordinate(latitude: 40, longitude: 20)), situation: situation)

        #expect(status.regionName == nil)
        #expect(status.alert == nil)
        #expect(status.miniMap == nil)
    }

    // MARK: - Alert

    @Test
    func make_whenNoAlert_reportsNone() {
        let status = makeSUT()

        #expect(status.alert == nil)
    }

    @Test(arguments: [
        (RegionAlertLevel?.none, HomeAlertLevel.red),
        (.yellow, .yellow),
        (.red, .red)
    ])
    func make_whenOblastAlerted_reportsAlertWithLevel(level: RegionAlertLevel?, expected: HomeAlertLevel) {
        let situation = AirSituation(alerts: [.stub(level: level, scope: .oblast, startedAt: FeedFixtures.date(-600))], threats: [])

        let status = makeSUT(situation: situation)

        #expect(status.alert == HomeAlert(level: expected, startedAt: FeedFixtures.date(-600)))
    }

    @Test
    func make_whenHromadaInHomesRaionAlerted_reportsAlert() {
        let situation = AirSituation(alerts: [.stub(level: .yellow, scope: .hromada, district: Constants.bucha)], threats: [])

        let status = makeSUT(situation: situation)

        #expect(status.alert == HomeAlert(level: .yellow, startedAt: FeedFixtures.origin))
    }

    @Test(arguments: [RegionAlertScope.raion, .hromada])
    func make_whenOnlyOtherRaionAlerted_reportsNoAlert(scope: RegionAlertScope) {
        let situation = AirSituation(alerts: [.stub(scope: scope, district: Constants.obukhiv)], threats: [])

        let status = makeSUT(situation: situation)

        #expect(status.alert == nil)
    }

    @Test
    func make_whenHomeInKyivAndOnlyKyivOblastAlerted_reportsNoAlert() {
        let situation = AirSituation(alerts: [.stub(scope: .oblast)], threats: [])

        let status = makeSUT(place: .stub(coordinate: MapFixtures.kyiv), situation: situation)

        #expect(status.regionName == "Київ")
        #expect(status.alert == nil)
    }

    @Test
    func make_whenHomeInKyivAndKyivAlerted_reportsAlert() {
        let situation = AirSituation(alerts: [.stub(scope: .city, name: "м. Київ", regionID: "UA-30")], threats: [])

        let status = makeSUT(place: .stub(coordinate: MapFixtures.kyiv), situation: situation)

        #expect(status.alert == HomeAlert(level: .red, startedAt: FeedFixtures.origin))
    }

    @Test
    func make_whenHomeInSevastopolAndCrimeaAlerted_reportsAlert() {
        let situation = AirSituation(alerts: [.stub(level: .yellow, scope: .oblast, name: "АР Крим", regionID: "UA-43")], threats: [])

        let status = makeSUT(place: .stub(coordinate: Constants.sevastopol), situation: situation)

        #expect(status.regionName == "Севастополь")
        #expect(status.alert == HomeAlert(level: .yellow, startedAt: FeedFixtures.origin))
    }

    // MARK: - Nearest threat

    @Test
    func make_whenConfirmedThreatInsideRadius_reportsItAsNearest() {
        let situation = AirSituation(alerts: [], threats: [threat(id: "t1", distanceKm: 5)])

        let status = makeSUT(situation: situation)

        #expect(status.nearestThreat == NearThreat(
            id: "t1",
            title: "Шахед",
            shortTitle: "Шахед",
            iconName: "threat-shahed",
            distanceText: "5 км від дому",
            shortDistanceText: "5 км",
            arrivalAt: nil,
            otherCount: 0
        ))
        #expect(status.closestThreat == nil)
    }

    @Test
    func make_whenSeveralThreatsInsideRadius_reportsNearestAndCountsOthersInside() {
        let situation = AirSituation(alerts: [], threats: [
            threat(id: "far", distanceKm: 8),
            threat(id: "near", distanceKm: 3),
            threat(id: "outside", distanceKm: 30)
        ])

        let status = makeSUT(situation: situation)

        #expect(status.nearestThreat?.id == "near")
        #expect(status.nearestThreat?.otherCount == 1)
    }

    @Test
    func make_whenThreatFliesAtPlace_reportsArrivalMoment() {
        let situation = AirSituation(alerts: [], threats: [threat(id: "t1", distanceKm: 20, heading: 180, speedKmh: 180)])

        let status = makeSUT(place: .stub(kind: .currentLocation, coordinate: Constants.home, radiusKm: 25), situation: situation)

        #expect(status.nearestThreat?.distanceText == "20 км від вас")
        let arrival = status.nearestThreat?.arrivalAt?.timeIntervalSince(FeedFixtures.origin) ?? -1
        #expect(abs(arrival - 400) < 0.01)
    }

    @Test
    func make_whenThreatCountNamed_titlesItWithCount() {
        let situation = AirSituation(alerts: [], threats: [threat(id: "t1", distanceKm: 5, count: 3)])

        let status = makeSUT(situation: situation)

        #expect(status.nearestThreat?.title == "Шахед ×3")
    }

    // MARK: - Closest threat outside the radius

    @Test
    func make_whenApproximateThreatTooRoughForRadius_reportsItOnlyAsClosest() {
        let rough = threat(id: "rough", distanceKm: 5, positionQuality: .approximate, accuracyKm: 40)
        let situation = AirSituation(alerts: [], threats: [rough])

        let status = makeSUT(situation: situation)

        #expect(status.nearestThreat == nil)
        #expect(status.closestThreat?.id == "rough")
        #expect(status.closestThreat?.distanceText == "у межах ±40 км від дому")
        #expect(status.closestThreat?.shortDistanceText == "±40 км")
        #expect(status.closestThreat?.otherCount == 0)
    }

    @Test
    func make_whenThreatOutsideRadiusWithin100Km_reportsItAsClosest() {
        let situation = AirSituation(alerts: [], threats: [threat(id: "t1", distanceKm: 60), threat(id: "t2", distanceKm: 90)])

        let status = makeSUT(situation: situation)

        #expect(status.nearestThreat == nil)
        #expect(status.closestThreat?.id == "t1")
        #expect(status.closestThreat?.distanceText == "60 км від дому")
    }

    @Test
    func make_whenThreatsBeyond100Km_reportsNone() {
        let situation = AirSituation(alerts: [], threats: [threat(id: "t1", distanceKm: 120)])

        let status = makeSUT(situation: situation)

        #expect(status.nearestThreat == nil)
        #expect(status.closestThreat == nil)
    }

    @Test
    func make_whenOnlyAreaKnown_reportsNone() {
        let areaOnly = Threat.stub(positionName: nil, areaCenter: Constants.home, positionQuality: .area)
        let situation = AirSituation(alerts: [], threats: [areaOnly])

        let status = makeSUT(situation: situation)

        #expect(status.nearestThreat == nil)
        #expect(status.closestThreat == nil)
    }

    @Test
    func make_whenTargetOnlyHeadsIntoRadius_reportsItByTarget() throws {
        let targetOnly = Threat.stub(
            id: "t2",
            positionName: nil,
            targetName: "Ірпінь",
            targetCoordinate: Constants.home,
            positionQuality: .targetOnly
        )
        let situation = AirSituation(alerts: [], threats: [targetOnly])

        let status = makeSUT(situation: situation)

        let threat = try #require(status.nearestThreat)
        #expect(threat.distanceText == "курсом на Ірпінь")
        #expect(threat.arrivalAt == nil)
        #expect(status.closestThreat == nil)
    }
}

// MARK: - Helpers

private extension HomeStatusFactoryTests {

    func makeSUT(
        place: WatchedPlace = .stub(coordinate: Constants.home, radiusKm: 10),
        situation: AirSituation = .empty,
        now: Date = FeedFixtures.origin
    ) -> HomeStatus {
        HomeStatusFactory.make(
            place: place,
            situation: situation,
            regions: Constants.regions,
            districts: Constants.districts,
            now: now
        )
    }

    /// A threat `distanceKm` due north of ``Constants/home``, reported at the fixtures' origin.
    func threat(
        id: String,
        distanceKm: Double,
        count: Int? = nil,
        positionQuality: ThreatPositionQuality = .confirmed,
        accuracyKm: Double = 2,
        heading: Double? = nil,
        speedKmh: Double = 150
    ) -> Threat {
        Threat.stub(
            id: id,
            count: count,
            positionCoordinate: Constants.home.moved(bearing: 0, distanceKm: distanceKm),
            positionQuality: positionQuality,
            accuracyKm: accuracyKm,
            heading: heading,
            speedKmh: speedKmh
        )
    }
}

// MARK: - Constants

private enum Constants {
    /// In the western raion of Kyiv Oblast, far enough from Kyiv for a 100 km circle not to matter.
    static let home = GeoCoordinate(latitude: 49.5, longitude: 29.5)
    static let sevastopol = GeoCoordinate(latitude: 44.6, longitude: 33.5)
    static let bucha = DistrictKey(regionID: "UA-32", name: "Бучанський")
    static let obukhiv = DistrictKey(regionID: "UA-32", name: "Обухівський")

    static let kyivCity = MapFixtures.square(center: MapFixtures.kyiv, halfSize: 0.2)
    static let sevastopolCity = MapFixtures.square(center: sevastopol, halfSize: 0.1)

    /// Kyiv Oblast with Kyiv cut out, Kyiv, Crimea with Sevastopol cut out, Sevastopol.
    static let regions = [
        RegionBoundary.stub(polygons: [MapFixtures.rectangle(south: 48, west: 29, north: 51.5, east: 31.5, holes: [kyivCity.exterior])]),
        RegionBoundary.stub(id: "UA-30", name: "Київ", polygons: [kyivCity]),
        RegionBoundary.stub(id: "UA-43", name: "АР Крим", polygons: [
            MapFixtures.rectangle(south: 44, west: 32, north: 46, east: 36, holes: [sevastopolCity.exterior])
        ]),
        RegionBoundary.stub(id: "UA-40", name: "Севастополь", polygons: [sevastopolCity])
    ]

    /// Kyiv Oblast split into a western and an eastern raion.
    static let districts = [
        DistrictBoundary.stub(name: bucha.name, polygons: [MapFixtures.rectangle(south: 48, west: 29, north: 51.5, east: 30)]),
        DistrictBoundary.stub(name: obukhiv.name, polygons: [MapFixtures.rectangle(south: 48, west: 30, north: 51.5, east: 31.5)])
    ]
}
