//
//  HomeAlertActivityController.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import ActivityKit
import Foundation
import HomeStatusKit
import OSLog

/// Runs one ``HomeAlertActivityAttributes`` Live Activity at a time through ActivityKit.
///
/// Two things start it — its *trigger*:
/// - a fresh air raid alert at the place, younger than ``Constants/maxAlertAge``;
/// - a threat inside the place's radius, with no alert or under an old one: in a frontline hromada the alert lasts for
///   days, and the threat is the news, not the alert.
///
/// It ends with «Відбій» when the alert that started it is lifted, and quietly once the radius has been clear for
/// ``Constants/clearLinger`` (so a threat on the edge does not make it blink). An activity the user swiped away is not
/// brought back for the same trigger; a new alert or a new threat gets a new one.
///
/// The user can turn it off in the settings: every one on screen goes at once, «Відбій» included, and none starts until
/// it is back on.
///
/// Updates come from the app only (no push token yet), so between launches it stays as the app last saw it; the
/// stale date dims it once the data is ``Constants/staleAfter`` old.
///
/// - Note: ActivityKit only starts an activity while the app is in the foreground; a request from the background
///   fails and is logged.
final class HomeAlertActivityController {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var activity: Activity<HomeAlertActivityAttributes>?
    private var lastState: HomeAlertActivityState?
    private var lastUpdatedAt: Date?
    /// What keeps the running activity on screen, e.g. `alert:1791902582` or `threat:ev1791904150_66`.
    private var trigger: String?
    /// When the running activity lost its trigger; it ends ``Constants/clearLinger`` later.
    private var clearSince: Date?
    /// The user's choice in the settings.
    private var isEnabled = true

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        // One left from the previous launch: keep following it instead of stacking a second one.
        activity = Activity<HomeAlertActivityAttributes>.activities.first { Self.isRunning($0.activityState) }
        lastState = activity?.content.state
    }
}

// MARK: - HomeAlertActivityControlling

extension HomeAlertActivityController: HomeAlertActivityControlling {

    func update(
        with status: HomeStatus?,
        updatedAt: Date
    ) {
        forgetFinishedActivity()
        guard isEnabled, let status else {
            end(finalState: nil)
            return
        }
        if let activity, activity.attributes.placeName != status.placeName || activity.attributes.placeKind != status.placeKind {
            // The home moved or replaced the location: the place is fixed for an activity's lifetime.
            end(finalState: nil)
        }
        let state = HomeAlertActivityState(
            alert: status.alert,
            nearestThreat: status.nearestThreat,
            closestThreat: status.closestThreat,
            radiusKm: status.radiusKm
        )
        if let newTrigger = Self.trigger(for: status, at: updatedAt) {
            clearSince = nil
            if activity == nil {
                start(
                    attributes: HomeAlertActivityAttributes(placeKind: status.placeKind, placeName: status.placeName),
                    state: state,
                    trigger: newTrigger,
                    updatedAt: updatedAt
                )
            } else {
                trigger = newTrigger
                refresh(with: state, updatedAt: updatedAt)
            }
        } else {
            wind(down: state, updatedAt: updatedAt)
        }
    }

    func setEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
        guard !isEnabled else { return }
        end(finalState: nil)
        // A lifted alert's «Відбій» is no longer followed but lingers on the lock screen; ending it again takes it off.
        for id in Activity<HomeAlertActivityAttributes>.activities.map(\.id) {
            Task {
                await Self.end(activityID: id, finalState: nil, dismissAt: nil)
            }
        }
    }
}

// MARK: - Private methods

private extension HomeAlertActivityController {

    static func isRunning(_ state: ActivityState) -> Bool {
        state == .active || state == .stale
    }

    /// A fresh alert first — it may come with no threat at all — then a threat inside the radius.
    static func trigger(
        for status: HomeStatus,
        at date: Date
    ) -> String? {
        if let alert = status.alert, date.timeIntervalSince(alert.startedAt) < Constants.maxAlertAge {
            return "alert:\(Int(alert.startedAt.timeIntervalSince1970))"
        }
        return status.nearestThreat.map { "threat:\($0.id)" }
    }

    /// Nothing keeps the activity any more: «Відбій» when the alert was lifted, otherwise it ends once the radius has
    /// stayed clear for a while.
    func wind(
        down state: HomeAlertActivityState,
        updatedAt: Date
    ) {
        guard activity != nil else { return }
        if state.alert == nil, lastState?.alert != nil {
            let allClear = HomeAlertActivityState(
                alert: nil,
                nearestThreat: nil,
                radiusKm: state.radiusKm,
                isAllClear: true
            )
            end(finalState: allClear, dismissAt: updatedAt.addingTimeInterval(Constants.allClearLinger))
            return
        }
        let since = clearSince ?? updatedAt
        clearSince = since
        if updatedAt.timeIntervalSince(since) >= Constants.clearLinger {
            end(finalState: nil)
        } else {
            refresh(with: state, updatedAt: updatedAt)
        }
    }

    /// Drops an activity that is no longer on screen; the trigger of one the user swiped away is remembered, so the
    /// same alert or threat does not bring it back.
    func forgetFinishedActivity() {
        guard let activity, !Self.isRunning(activity.activityState) else { return }
        if activity.activityState == .dismissed, let trigger {
            defaults.set(trigger, forKey: Constants.dismissedTriggerKey)
        }
        self.activity = nil
        lastState = nil
        trigger = nil
        clearSince = nil
    }

    func start(
        attributes: HomeAlertActivityAttributes,
        state: HomeAlertActivityState,
        trigger: String,
        updatedAt: Date
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              defaults.string(forKey: Constants.dismissedTriggerKey) != trigger
        else { return }
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content(state, updatedAt: updatedAt),
                pushType: nil
            )
            lastState = state
            lastUpdatedAt = updatedAt
            self.trigger = trigger
        } catch {
            logger.error("Failed to start the Live Activity: \(String(describing: error), privacy: .public)")
        }
    }

    /// Sends the state when it changed, or when the last update is about to turn stale while the app is still live.
    func refresh(
        with state: HomeAlertActivityState,
        updatedAt: Date
    ) {
        guard let activity else { return }
        let isDue = lastUpdatedAt.map { updatedAt.timeIntervalSince($0) >= Constants.keepFreshInterval } ?? true
        guard state != lastState || isDue else { return }
        lastState = state
        lastUpdatedAt = updatedAt
        let id = activity.id
        let staleDate = updatedAt.addingTimeInterval(Constants.staleAfter)
        let relevanceScore = Self.relevanceScore(of: state)
        Task {
            await Self.update(activityID: id, state: state, staleDate: staleDate, relevanceScore: relevanceScore)
        }
    }

    /// Ends the running activity, showing `finalState` until `dismissAt` — «Відбій» for a lifted alert; without a
    /// moment it goes at once.
    func end(
        finalState: HomeAlertActivityState?,
        dismissAt: Date? = nil
    ) {
        guard let activity else { return }
        self.activity = nil
        lastState = nil
        lastUpdatedAt = nil
        trigger = nil
        clearSince = nil
        let id = activity.id
        Task {
            await Self.end(activityID: id, finalState: finalState, dismissAt: dismissAt)
        }
    }

    func content(
        _ state: HomeAlertActivityState,
        updatedAt: Date
    ) -> ActivityContent<HomeAlertActivityState> {
        ActivityContent(
            state: state,
            staleDate: updatedAt.addingTimeInterval(Constants.staleAfter),
            relevanceScore: Self.relevanceScore(of: state)
        )
    }

    /// Above other activities while a threat is inside the radius.
    static func relevanceScore(of state: HomeAlertActivityState) -> Double {
        state.nearestThreat == nil ? Constants.alertRelevance : Constants.threatRelevance
    }
}

// MARK: - ActivityKit

/// `Activity` is not `Sendable`, so it never leaves the main actor: updates run off it on the activity looked up by its
/// id, and only `Sendable` values cross over.
nonisolated private extension HomeAlertActivityController {

    @concurrent
    static func update(
        activityID: String,
        state: HomeAlertActivityState,
        staleDate: Date,
        relevanceScore: Double
    ) async {
        let content = ActivityContent(state: state, staleDate: staleDate, relevanceScore: relevanceScore)
        await activity(id: activityID)?.update(content)
    }

    @concurrent
    static func end(
        activityID: String,
        finalState: HomeAlertActivityState?,
        dismissAt: Date?
    ) async {
        let content = finalState.map { ActivityContent(state: $0, staleDate: nil) }
        let dismissal: ActivityUIDismissalPolicy = dismissAt.map { .after($0) } ?? .immediate
        await activity(id: activityID)?.end(content, dismissalPolicy: dismissal)
    }

    static func activity(id: String) -> Activity<HomeAlertActivityAttributes>? {
        Activity<HomeAlertActivityAttributes>.activities.first { $0.id == id }
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "LiveActivity"
    static let dismissedTriggerKey = "liveActivityDismissedTrigger"
    /// iOS keeps an activity for eight hours; an older alert alone is the place's normal state, not news.
    static let maxAlertAge: TimeInterval = 8 * 60 * 60
    /// How long the radius must stay clear before a threat-started activity ends.
    static let clearLinger: TimeInterval = 5 * 60
    static let staleAfter: TimeInterval = 15 * 60
    static let keepFreshInterval: TimeInterval = 10 * 60
    /// How long «Відбій» stays on the lock screen.
    static let allClearLinger: TimeInterval = 15 * 60
    static let alertRelevance: Double = 50
    static let threatRelevance: Double = 100
}
