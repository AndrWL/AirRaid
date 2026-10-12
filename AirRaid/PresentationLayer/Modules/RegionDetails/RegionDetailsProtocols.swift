//
//  RegionDetailsProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// Defines the state of the region sheet: one region's alerts and threats, followed live while the sheet is open.
protocol RegionDetailsViewModelProtocol: BaseViewModelProtocol {

    /// The sheet's content at the given moment, or `nil` until the region's name is loaded.
    ///
    /// Takes the moment instead of storing it, so the view can refresh durations on its own schedule.
    func content(at date: Date) -> RegionDetailsContent?

    /// Loads the region's name. Safe to call on every appearance.
    func onAppear() async
}
