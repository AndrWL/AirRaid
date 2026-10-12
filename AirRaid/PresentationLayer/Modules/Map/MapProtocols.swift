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

    /// ISO codes of the regions the user follows, outlined on the map.
    var favoriteRegionIDs: [String] { get }

    /// The followed regions with their alert state, in the order they were added; empty until the outlines load.
    var favoriteChips: [FavoriteRegionChip] { get }

    /// The threat or region whose sheet is open, highlighted on the map; `nil` when none is.
    var selection: MapSelection? { get }

    /// Loads the region outlines and city labels. Safe to call on every appearance.
    func onAppear() async

    /// Opens the sheet of the tapped threat or region, or closes it when the tap hit neither.
    func didSelect(_ selection: MapSelection?)
}

/// Defines the routing capabilities for the Map flow.
protocol MapRouterProtocol: BaseRouterProtocol, SheetPresenting where SheetRoute == MapSheetRoute {

}

/// A protocol that defines the requirements for a Map flow factory.
protocol MapFactoryProtocol {
    associatedtype Sheet: View

    @ViewBuilder func sheet(for route: MapSheetRoute) -> Sheet
}
