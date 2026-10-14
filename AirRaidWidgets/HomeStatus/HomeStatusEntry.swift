//
//  HomeStatusEntry.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import HomeStatusKit
import WidgetKit

/// One moment of the home status widget.
nonisolated struct HomeStatusEntry: TimelineEntry {

    /// What the widget can show.
    enum Content: Hashable {

        /// The app has not written anything yet, or is signed without the App Group.
        case noData

        /// No home pin and no location to stand in for it.
        case noPlace

        case home(HomeStatus)
    }

    // MARK: - Variables

    let date: Date

    let content: Content

    /// When the app last had live data; `nil` with ``Content/noData``.
    let updatedAt: Date?

    /// The data is old enough to say so: the app has been closed for a while.
    var isStale: Bool {
        updatedAt.map { date.timeIntervalSince($0) >= Self.staleAfter } ?? false
    }

    /// Longer than the app's 10-minute refresh while it is open, so a live app never shows the note.
    static let staleAfter: TimeInterval = 30 * 60

    init(
        date: Date,
        snapshot: HomeStatusSnapshot?
    ) {
        self.date = date
        updatedAt = snapshot?.updatedAt
        switch snapshot?.home {
        case .some(let home): content = .home(home)
        case .none: content = snapshot == nil ? .noData : .noPlace
        }
    }
}
