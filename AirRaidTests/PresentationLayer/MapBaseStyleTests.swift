//
//  MapBaseStyleTests.swift
//  AirRaidTests
//

import SwiftUI
import Testing
@testable import AirRaid

/// Tests for ``MapBaseStyle``: «Як у системі» and «Детальна» follow the appearance, «Темна» and «Світла» ignore it.
@MainActor
@Suite
struct MapBaseStyleTests {

    @Test(arguments: [
        (MapStylePreference.system, ColorScheme.dark, MapBaseStyle.dark),
        (.system, .light, .light),
        (.dark, .light, .dark),
        (.light, .dark, .light),
        (.detailed, .light, .detailed),
        (.detailed, .dark, .detailedDark)
    ])
    func init_whenPreferenceAndSchemeGiven_resolvesStyle(
        preference: MapStylePreference,
        colorScheme: ColorScheme,
        expected: MapBaseStyle
    ) {
        #expect(MapBaseStyle(preference, colorScheme: colorScheme) == expected)
    }

    @Test
    func isDark_isTrueForBothDarkStyles() {
        #expect(MapBaseStyle.dark.isDark)
        #expect(MapBaseStyle.detailedDark.isDark)
        #expect(!MapBaseStyle.light.isDark)
        #expect(!MapBaseStyle.detailed.isDark)
    }

    @Test
    func detailedDark_sharesDetailedStyleAndDarkensIt() {
        #expect(MapBaseStyle.detailedDark.styleURL == MapBaseStyle.detailed.styleURL)
        #expect(MapBaseStyle.detailedDark.darkensBasemap)
        #expect(!MapBaseStyle.dark.darkensBasemap)
    }
}
