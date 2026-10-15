//
//  UpgradeNoticeTests.swift
//  AirRaidTests
//

import Foundation
import Testing
@testable import AirRaid

/// Tests for ``UpgradeNotice/next(after:state:appStoreURL:)`` and the map's ``MapConnectionNotice/upgradeRequired``.
///
/// Covers that only a refused version prompts an update, that the prompt survives the reconnect that re-checks the
/// version and clears only once connected, that the App Store link (and so the button) is optional, and that the map
/// says it in the same words as the feed and the settings.
@MainActor
@Suite
struct UpgradeNoticeTests {

    // MARK: - Showing the notice

    @Test
    func next_whenUpgradeRequired_carriesAppStoreURL() throws {
        let appStoreURL = try #require(URL(string: Constants.appStoreURLString))

        let sut = UpgradeNotice.next(after: nil, state: .upgradeRequired, appStoreURL: appStoreURL)

        #expect(sut == UpgradeNotice(appStoreURL: appStoreURL))
    }

    @Test
    func next_whenNoAppStoreID_promptsWithoutLink() {
        let sut = UpgradeNotice.next(after: nil, state: .upgradeRequired, appStoreURL: nil)

        #expect(sut == UpgradeNotice(appStoreURL: nil))
    }

    @Test(arguments: [
        RealtimeConnectionState.connected,
        .connecting,
        .disconnected,
        .waitingForNetwork
    ])
    func next_whenNothingShownAndVersionNotRefused_returnsNil(state: RealtimeConnectionState) throws {
        let appStoreURL = try #require(URL(string: Constants.appStoreURLString))

        let sut = UpgradeNotice.next(after: nil, state: state, appStoreURL: appStoreURL)

        #expect(sut == nil)
    }

    // MARK: - Keeping and clearing it

    @Test(arguments: [
        RealtimeConnectionState.connecting,
        .disconnected,
        .waitingForNetwork
    ])
    func next_whenShownAndReconnecting_keepsIt(state: RealtimeConnectionState) {
        let shown = UpgradeNotice(appStoreURL: nil)

        let sut = UpgradeNotice.next(after: shown, state: state, appStoreURL: nil)

        #expect(sut == shown)
    }

    @Test
    func next_whenShownAndConnected_clearsIt() {
        let sut = UpgradeNotice.next(after: UpgradeNotice(appStoreURL: nil), state: .connected, appStoreURL: nil)

        #expect(sut == nil)
    }

    // MARK: - Map wording

    @Test
    func mapNotice_whenUpgradeRequired_saysWhatTheFeedSays() throws {
        let sut = try #require(MapConnectionNotice(state: .upgradeRequired, liveUntil: Date(timeIntervalSince1970: 0)))

        #expect(sut == .upgradeRequired)
        #expect(sut.title == UpgradeNotice.title)
        #expect(sut.subtitle == UpgradeNotice.subtitle)
        #expect(sut.systemImage == UpgradeNotice.systemImage)
        #expect(!sut.isInProgress)
    }
}

// MARK: - Constants

private enum Constants {
    static let appStoreURLString = "https://apps.apple.com/app/id1234567890"
}
