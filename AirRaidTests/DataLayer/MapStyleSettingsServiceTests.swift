//
//  MapStyleSettingsServiceTests.swift
//  AirRaidTests
//

import Combine
import Foundation
import Testing
@testable import AirRaid

/// Tests for ``MapStyleSettingsService``: «Як у системі» until the user picks a style, and the pick kept across launches.
@MainActor
@Suite
struct MapStyleSettingsServiceTests {

    @Test
    func preference_whenNothingStored_isSystem() {
        let sut = makeSUT()

        #expect(current(of: sut) == .system)
    }

    @Test
    func setPreference_whenNewServiceReads_keepsChoice() {
        let defaults = makeDefaults()
        makeSUT(defaults: defaults).setPreference(.detailed)

        let sut = makeSUT(defaults: defaults)

        #expect(current(of: sut) == .detailed)
    }

    @Test
    func preference_whenStoredValueUnknown_fallsBackToSystem() {
        let defaults = makeDefaults()
        defaults.set("satellite", forKey: Constants.preferenceKey)

        let sut = makeSUT(defaults: defaults)

        #expect(current(of: sut) == .system)
    }
}

// MARK: - Helpers

private extension MapStyleSettingsServiceTests {

    func makeSUT(defaults: UserDefaults? = nil) -> MapStyleSettingsService {
        MapStyleSettingsService(defaults: defaults ?? makeDefaults())
    }

    func makeDefaults() -> UserDefaults {
        let suiteName = "MapStyleSettingsServiceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// The value a subscriber gets at once: the publisher is backed by a `CurrentValueSubject`.
    func current(of sut: MapStyleSettingsService) -> MapStylePreference? {
        var value: MapStylePreference?
        let cancellable = sut.preferencePublisher.sink { value = $0 }
        cancellable.cancel()
        return value
    }
}

// MARK: - Constants

private enum Constants {
    static let preferenceKey = "mapStylePreference"
}
