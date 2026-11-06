//
//  HomeAlertActivityControlling.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import HomeStatusKit

/// Runs the Live Activity that follows an air raid alert at the home, or at the user's location without a home.
protocol HomeAlertActivityControlling {

    /// Starts the activity when an alert at the home begins, updates it while it lasts and ends it with the all clear.
    ///
    /// - Parameters:
    ///   - status: The watched place's status (the home, else the user's location), or `nil` when there is neither —
    ///     any running activity ends at once.
    ///   - updatedAt: When the status was last live, for the activity's stale date.
    func update(
        with status: HomeStatus?,
        updatedAt: Date
    )

    /// Turned off in the settings: the running activity ends at once and no new one starts until it is turned on
    /// again. On by default.
    func setEnabled(_ isEnabled: Bool)
}
