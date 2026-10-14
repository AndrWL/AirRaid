//
//  HomeStatusProvider.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import HomeStatusKit
import OSLog
import WidgetKit

/// Reads the app's last snapshot from the App Group file.
///
/// The timeline is static (`.never`): the app reloads it whenever the status changes. Extra entries only re-render it
/// at moments that change what it shows by themselves — when the forecast arrival passes, when the data turns stale and
/// at midnight, when «з 10:28» has to become «з 14 жовт.».
nonisolated struct HomeStatusProvider: TimelineProvider {

    func placeholder(in context: Context) -> HomeStatusEntry {
        HomeStatusEntry(date: .now, snapshot: .previewAlert)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (HomeStatusEntry) -> Void
    ) {
        // The widget gallery: a sample beats an empty «open the app».
        let snapshot = context.isPreview ? .previewAlert : loadSnapshot()
        completion(HomeStatusEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<HomeStatusEntry>) -> Void
    ) {
        let now = Date()
        let snapshot = loadSnapshot()
        let moments = [
            snapshot?.home?.nearestThreat?.arrivalAt,
            snapshot.map { $0.updatedAt.addingTimeInterval(HomeStatusEntry.staleAfter) },
            snapshot?.home?.alert == nil ? nil : nextMidnight(after: now)
        ]
        let entries = [HomeStatusEntry(date: now, snapshot: snapshot)]
            + moments.compactMap { $0 }.filter { $0 > now }.sorted().map { HomeStatusEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .never))
    }
}

// MARK: - Private methods

nonisolated private extension HomeStatusProvider {

    /// One is enough: past midnight the alert's start reads as a date, and a date stays right on every later day.
    func nextMidnight(after date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
    }

    func loadSnapshot() -> HomeStatusSnapshot? {
        do {
            return try HomeStatusStore().load()
        } catch {
            Logger(subsystem: Constants.subsystem, category: Constants.category)
                .error("Failed to read the snapshot: \(String(describing: error), privacy: .public)")
            return nil
        }
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let subsystem = "AirRaidWidgets"
    static let category = "HomeStatus"
}
