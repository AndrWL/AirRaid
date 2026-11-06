//
//  HomeWidgetPublisher.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import HomeStatusKit
import OSLog
import WidgetKit

/// Writes the snapshot to the App Group file and reloads the widget's timeline.
///
/// A reload redraws every widget the user placed, and reloads from the background count against a daily budget, so
/// it happens only when the content changes — plus every ``Constants/keepFreshInterval`` while the app is live, so
/// the widget's "data as of …" note never appears over data that is in fact current.
final class HomeWidgetPublisher {

    // MARK: - Variables

    private let store: HomeStatusStore
    private let widgetCenter: WidgetCenter
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var lastSaved: HomeStatusSnapshot?
    private var hasReportedMissingContainer = false

    init(
        store: HomeStatusStore = HomeStatusStore(),
        widgetCenter: WidgetCenter = .shared
    ) {
        self.store = store
        self.widgetCenter = widgetCenter
    }
}

// MARK: - HomeWidgetPublishing

extension HomeWidgetPublisher: HomeWidgetPublishing {

    func publish(_ snapshot: HomeStatusSnapshot) {
        guard store.isAvailable else {
            reportMissingContainer()
            return
        }
        let isDue = lastSaved.map { snapshot.updatedAt.timeIntervalSince($0.updatedAt) >= Constants.keepFreshInterval } ?? true
        guard isDue || !snapshot.hasSameContent(as: lastSaved) else { return }
        do {
            try store.save(snapshot)
        } catch {
            logger.error("Failed to save the widget snapshot: \(String(describing: error), privacy: .public)")
            return
        }
        lastSaved = snapshot
        widgetCenter.reloadTimelines(ofKind: HomeStatusSnapshot.widgetKind)
    }
}

// MARK: - Private methods

private extension HomeWidgetPublisher {

    /// Once per launch: a build signed without the App Group (a free Personal Team) is expected to have none.
    func reportMissingContainer() {
        guard !hasReportedMissingContainer else { return }
        hasReportedMissingContainer = true
        logger.notice("No App Group container (\(AppGroup.identifier, privacy: .public)): the widgets get no data")
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Widgets"
    static let keepFreshInterval: TimeInterval = 10 * 60
}
