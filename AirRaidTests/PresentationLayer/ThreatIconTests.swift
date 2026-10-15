//
//  ThreatIconTests.swift
//  AirRaidTests
//

import Testing
import UIKit
@testable import AirRaid

/// Tests for ``ThreatIcon``.
///
/// Covers that every icon, and so every threat type the app knows, has its silhouette in the asset catalog: a missing
/// one only trips an assertion and leaves the map pin empty.
@MainActor
@Suite
struct ThreatIconTests {

    @Test(arguments: ThreatIcon.allCases)
    func name_whenAnyIcon_namesExistingAsset(icon: ThreatIcon) {
        #expect(UIImage(named: icon.name) != nil)
    }

    @Test
    func init_whenMolniya_usesItsOwnIcon() {
        #expect(ThreatIcon(ThreatType.molniya) == .molniya)
    }
}
