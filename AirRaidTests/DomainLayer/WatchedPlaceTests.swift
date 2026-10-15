//
//  WatchedPlaceTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``WatchedPlace/places(currentLocation:settings:includesCustomPlaces:)`` and ``WatchedPlace/init(_:)``.
///
/// Covers the current location always first with its own radius, the free plan watching only the home, Плюс
/// watching up to ``PremiumLimits/plusPlaces`` saved places, and how a saved place becomes a watched one.
@Suite
struct WatchedPlaceTests {

    // MARK: - places(currentLocation:settings:includesCustomPlaces:)

    @Test
    func places_whenNothingKnown_returnsNothing() {
        let places = WatchedPlace.places(currentLocation: nil, settings: .initial, includesCustomPlaces: true)

        #expect(places.isEmpty)
    }

    @Test
    func places_whenLocationKnown_putsItFirstWithItsOwnRadius() throws {
        let settings = makeSettings(places: [Constants.home, Constants.work], currentLocationRadiusKm: 50)

        let places = WatchedPlace.places(currentLocation: MapFixtures.kyiv, settings: settings, includesCustomPlaces: true)

        let first = try #require(places.first)
        #expect(first == WatchedPlace(
            id: WatchedPlace.currentLocationID,
            kind: .currentLocation,
            name: nil,
            coordinate: MapFixtures.kyiv,
            radiusKm: 50
        ))
        #expect(places.map(\.id) == [WatchedPlace.currentLocationID, Constants.home.id.uuidString, Constants.work.id.uuidString])
    }

    @Test
    func places_whenFreePlan_watchesOnlyHomeAndLocation() {
        let settings = makeSettings(places: [Constants.home, Constants.work, Constants.school])

        let places = WatchedPlace.places(currentLocation: MapFixtures.kyiv, settings: settings, includesCustomPlaces: false)

        #expect(places.map(\.kind) == [.currentLocation, .home])
        #expect(places.last?.id == Constants.home.id.uuidString)
    }

    @Test
    func places_whenFreePlanWithoutHome_watchesOnlyLocation() {
        let settings = makeSettings(places: [Constants.work])

        let places = WatchedPlace.places(currentLocation: MapFixtures.kyiv, settings: settings, includesCustomPlaces: false)

        #expect(places.map(\.kind) == [.currentLocation])
    }

    @Test
    func places_whenPlusAndNoLocation_watchesSavedPlacesInOrder() {
        let settings = makeSettings(places: [Constants.home, Constants.work, Constants.school])

        let places = WatchedPlace.places(currentLocation: nil, settings: settings, includesCustomPlaces: true)

        #expect(places.map(\.id) == [Constants.home, Constants.work, Constants.school].map(\.id.uuidString))
        #expect(places.map(\.kind) == [.home, .custom, .custom])
    }

    @Test
    func places_whenPlusAndMorePlacesThanLimit_watchesFirstOnesUpToLimit() {
        let saved = [Constants.home] + (1..<(PremiumLimits.plusPlaces + 3)).map { index in
            SavedPlace(kind: .custom, name: "Місце \(index)", coordinate: MapFixtures.kyiv, radiusKm: 10)
        }
        let settings = makeSettings(places: saved)

        let places = WatchedPlace.places(currentLocation: MapFixtures.kyiv, settings: settings, includesCustomPlaces: true)

        #expect(places.count == PremiumLimits.plusPlaces + 1)
        #expect(places.first?.kind == .currentLocation)
        #expect(Array(places.dropFirst()).map(\.id) == saved.prefix(PremiumLimits.plusPlaces).map(\.id.uuidString))
    }

    // MARK: - init(_ place:)

    @Test
    func init_whenHome_hasNoNameAndKeepsRadiusAndAddress() {
        let address = PlaceAddress(locality: "Ірпінь", street: nil)
        let home = SavedPlace(kind: .home, name: "Мій дім", coordinate: MapFixtures.kyiv, radiusKm: 5, address: address)

        let sut = WatchedPlace(home)

        #expect(sut == WatchedPlace(
            id: home.id.uuidString,
            kind: .home,
            name: nil,
            coordinate: MapFixtures.kyiv,
            radiusKm: 5,
            address: address
        ))
    }

    @Test
    func init_whenCustomPlaceNamed_usesItsName() {
        let place = SavedPlace(kind: .custom, name: "Робота", coordinate: MapFixtures.kyiv, radiusKm: 10)

        let sut = WatchedPlace(place)

        #expect(sut.kind == .custom)
        #expect(sut.name == "Робота")
    }

    @Test
    func init_whenCustomPlaceUnnamed_fallsBackToLocality() {
        let address = PlaceAddress(locality: "Ірпінь", street: nil)
        let place = SavedPlace(kind: .custom, coordinate: MapFixtures.kyiv, radiusKm: 10, address: address)

        let sut = WatchedPlace(place)

        #expect(sut.name == "Ірпінь")
    }

    // MARK: - contains(_:)

    @Test
    func contains_whenPointOnRadius_returnsTrueAndJustPastIt_returnsFalse() {
        let sut = WatchedPlace.stub(coordinate: MapFixtures.kyiv, radiusKm: 10)

        let inside = sut.contains(MapFixtures.kyiv.moved(bearing: 90, distanceKm: 9.99))
        let outside = sut.contains(MapFixtures.kyiv.moved(bearing: 90, distanceKm: 10.01))

        #expect(inside)
        #expect(!outside)
    }
}

// MARK: - Helpers

private extension WatchedPlaceTests {

    func makeSettings(
        places: [SavedPlace],
        currentLocationRadiusKm: Double = PlaceSettings.defaultRadiusKm
    ) -> PlaceSettings {
        PlaceSettings(places: places, currentLocationRadiusKm: currentLocationRadiusKm)
    }
}

// MARK: - Constants

private enum Constants {
    static let home = SavedPlace(kind: .home, coordinate: MapFixtures.bilaTserkva, radiusKm: 25)
    static let work = SavedPlace(kind: .custom, name: "Робота", coordinate: MapFixtures.kyiv, radiusKm: 10)
    static let school = SavedPlace(kind: .custom, name: "Школа", coordinate: MapFixtures.kyiv, radiusKm: 5)
}
