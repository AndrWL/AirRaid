//
//  MapProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import SwiftUI

/// Defines the state the Map screen renders: region outlines, which of them have an alert, and threat pins.
protocol MapViewModelProtocol: BaseViewModelProtocol {

    /// The MapLibre style of the base map.
    var styleURL: URL { get }

    /// Outlines of all regions; empty until loaded.
    var boundaries: [RegionBoundary] { get }

    /// Regional centers to label; empty until loaded.
    var cities: [City] { get }

    /// Raion outlines for raion-level alerts; empty until loaded.
    var districts: [DistrictBoundary] { get }

    /// Which oblasts and raions are under an air raid alert.
    var alertCoverage: AirRaidCoverage { get }

    /// Threats to show as pins.
    var threats: [Threat] { get }

    /// Why the map is not live right now; `nil` while it is.
    var connectionNotice: MapConnectionNotice? { get }

    /// The threat whose details are open, highlighted on the map with its track; `nil` when none is.
    var selectedThreatID: String? { get }

    /// Loads the region outlines and city labels. Safe to call on every appearance.
    func onAppear() async

    /// Opens the details of the tapped threat, or closes them when the tap missed every pin.
    func didSelectThreat(id: String?)
}

/// Defines the routing capabilities for the Map flow.
protocol MapRouterProtocol: BaseRouterProtocol, SheetPresenting where SheetRoute == MapSheetRoute {

}

/// A protocol that defines the requirements for a Map flow factory.
protocol MapFactoryProtocol {
    associatedtype Sheet: View

    @ViewBuilder func sheet(for route: MapSheetRoute) -> Sheet
}
