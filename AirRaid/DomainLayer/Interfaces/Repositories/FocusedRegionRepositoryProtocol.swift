//
//  FocusedRegionRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine

/// The one region the map is narrowed to, if any: the rest of the country is dimmed and the camera stays on it.
protocol FocusedRegionRepositoryProtocol {

    /// The ISO 3166-2 code of the focused region, or `nil` for the whole country; emits the current value on
    /// subscription and every change after it.
    var focusedRegionIDPublisher: AnyPublisher<String?, Never> { get }

    /// Focuses the map on the region, or shows the whole country again for `nil`.
    func setFocusedRegion(_ regionID: String?)
}
