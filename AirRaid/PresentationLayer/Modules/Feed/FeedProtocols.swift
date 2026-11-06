//
//  FeedProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import HomeStatusKit
import SwiftUI

/// Defines the state of the Feed tab: the bubbles, the filters, the voice and what is unread.
protocol FeedViewModelProtocol: BaseViewModelProtocol {

    /// The bubbles to show, oldest first, like a chat.
    var rows: [FeedRow] { get }

    /// Active critical bubbles, pinned above the feed while they last.
    var pinnedRows: [FeedRow] { get }

    /// The home's status as the widgets show it; `nil` without a place.
    var homeStatus: HomeStatus? { get }

    var scope: FeedScope { get }

    var kindFilter: FeedKindFilter { get }

    var isPlusActive: Bool { get }

    /// The bubble before which the "Unread" divider goes; `nil` when everything was seen.
    var firstUnreadID: String? { get }

    /// How many older bubbles only Plus shows.
    var hiddenHistoryCount: Int { get }

    var isVoiceLive: Bool { get }

    var isSpeaking: Bool { get }

    /// Whether the user has no place yet, so "My places" can show only country-wide reports.
    var hasNoPlaces: Bool { get }

    /// Set while the server refuses this app version, so no new bubbles can arrive; `nil` otherwise.
    var upgradeNotice: UpgradeNotice? { get }

    func onAppear()

    func onDisappear()

    func didSelectScope(_ scope: FeedScope)

    /// Opens the paywall instead for anything but ``FeedKindFilter/all`` without Plus.
    func didSelectKindFilter(_ filter: FeedKindFilter)

    /// Opens a threat that is still on the map.
    func didTapRow(id: String)

    /// Reads the bubble aloud once.
    func didTapReadAloud(id: String)

    func didToggleVoice()

    func didTapNightReport()

    func didTapHistoryUpsell()
}

/// Defines the routing capabilities for the Feed flow.
protocol FeedRouterProtocol: BaseRouterProtocol, SheetPresenting where SheetRoute == FeedSheetRoute {

    /// Switches to the map and opens the threat there.
    func showThreatOnMap(id: String)
}

/// A protocol that defines the requirements for a Feed flow factory.
protocol FeedFactoryProtocol {

    associatedtype Sheet: View

    @ViewBuilder func sheet(for route: FeedSheetRoute) -> Sheet
}
