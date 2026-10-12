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

    /// The region the map is narrowed to, or `nil` for the whole country.
    var focusedRegionID: String? { get }

    /// The focused region's name; `nil` without a focus or until the outlines load.
    var focusedRegionName: String? { get }

    /// Changes whenever the camera should fit the focused region (or the country) again.
    var recenterRequest: Int { get }

    /// The user's location, for the blue dot; `nil` without permission or a fix.
    var userLocation: GeoCoordinate? { get }

    /// Whether the app may read the user's location.
    var locationAuthorization: LocationAuthorization { get }

    /// Where the camera should fly next: to the user, or to the home when picking it.
    var flyRequest: MapFlyRequest? { get }

    /// Set when "to me" is tapped with location denied: only the Settings app can allow it.
    var isLocationDeniedAlertPresented: Bool { get }

    /// The threat or region whose sheet is open, highlighted on the map; `nil` when none is.
    var selection: MapSelection? { get }

    /// Loads the region outlines and city labels. Safe to call on every appearance.
    func onAppear() async

    /// The user's location and home with their radii, drawn on the map.
    var places: [WatchedPlace] { get }

    /// Whether the map is in home-picking mode: a fixed pin in the centre, the map moves under it.
    var isPickingHome: Bool { get }

    /// Whether a home is set, so the confirmation can say "move" instead of "set".
    var placeSettings: PlaceSettings { get }

    /// The nearest threat inside the radius of one of the user's places at the given moment; `nil` when the radii are
    /// clear.
    func nearestThreat(at date: Date) -> NearestThreatSummary?

    /// Opens the places sheet: the radii and the home.
    func didTapPlaces()

    /// Closes the places sheet and lets the user move the map under a centre pin to place the home.
    func didStartPickingHome()

    /// Follows the point under the centre of the map.
    func didChangeMapCenter(_ center: GeoCoordinate)

    /// Puts the home under the centre pin and leaves picking mode.
    func didConfirmHomePick()

    func didCancelHomePick()

    /// Flies to the user, asking for permission first if it was never asked.
    func didTapLocate()

    func didDismissLocationDeniedAlert()

    /// Moves the camera back onto the focused region.
    func didTapRecenter()

    /// Shows the whole country again.
    func didTapExitFocus()

    /// Opens the sheet of the tapped threat or region, or closes it when the tap hit neither.
    func didSelect(_ selection: MapSelection?)
}

/// Defines the routing capabilities for the Map flow.
protocol MapRouterProtocol: BaseRouterProtocol, SheetPresenting where SheetRoute == MapSheetRoute {

}

/// A protocol that defines the requirements for a Map flow factory.
protocol MapFactoryProtocol {
    associatedtype Sheet: View

    @ViewBuilder func sheet(for route: MapSheetRoute, actions: MapSheetActions) -> Sheet
}
