//
//  MapProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Foundation

/// Defines the state the Map screen renders: region outlines, which of them have an alert, and threat pins.
protocol MapViewModelProtocol: BaseViewModelProtocol {

    /// The MapLibre style of the base map.
    var styleURL: URL { get }

    /// Outlines of all regions; empty until loaded.
    var boundaries: [RegionBoundary] { get }

    /// Regional centers to label; empty until loaded.
    var cities: [City] { get }

    /// ISO 3166-2 codes of the regions that have an active alert.
    var alertedRegionIDs: Set<String> { get }

    /// Threats to show as pins.
    var threats: [Threat] { get }

    /// Loads the region outlines and city labels. Safe to call on every appearance.
    func onAppear() async
}

/// Defines the routing capabilities for the Map flow.
///
/// Empty for now; region details will be presented from here.
protocol MapRouterProtocol: BaseRouterProtocol {

}
