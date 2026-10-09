//
//  ThreatDetailsProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Defines the state of the threat details sheet: one threat, followed live while the sheet is open.
protocol ThreatDetailsViewModelProtocol: BaseViewModelProtocol {

    /// The sheet's content at the given moment, or `nil` when the threat was never found in the situation.
    ///
    /// Takes the moment instead of storing it, so the view can refresh relative times on its own schedule.
    func content(at date: Date) -> ThreatDetailsContent?
}
