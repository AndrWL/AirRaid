//
//  MapProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import SwiftUI

/// Defines the state the Map screen renders: region outlines, which of them have an alert, and threat pins.
protocol MapViewModelProtocol: BaseViewModelProtocol {

    /// The base map's look, as chosen in the settings; «Як у системі» is resolved by the view.
    var mapStylePreference: MapStylePreference { get }

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

    /// The App Store page for the update button of ``MapConnectionNotice/upgradeRequired``; `nil` hides the button.
    var appStoreURL: URL? { get }

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

    /// Where the camera should fly next: to the user, or to a place when picking it.
    var flyRequest: MapFlyRequest? { get }

    /// Set when "to me" is tapped with location denied: only the Settings app can allow it.
    var isLocationDeniedAlertPresented: Bool { get }

    /// Threats whose reported position is inside the radius of one of the watched places; drawn red.
    var nearThreatIDs: Set<String> { get }

    /// Grows each time a threat comes within a radius, for a haptic alongside the sound.
    var nearThreatAlertCount: Int { get }

    /// The threat or region whose sheet is open, highlighted on the map; `nil` when none is.
    var selection: MapSelection? { get }

    /// Loads the region outlines and city labels. Safe to call on every appearance.
    func onAppear() async

    /// The watched places with their radii, drawn on the map.
    var places: [WatchedPlace] { get }

    /// What the map is placing under a fixed pin in the centre, or `nil` outside picking mode.
    var placePick: PlacePick? { get }

    /// Grows with every confirmed pick, for a haptic.
    var placePickConfirmCount: Int { get }

    /// The custom place just added, waiting for the user to name it; `nil` once named or skipped.
    var namingPlaceID: SavedPlace.ID? { get set }

    /// The saved places, so the confirmation can say "move" instead of "set".
    var placeSettings: PlaceSettings { get }

    /// For each of the user's places, the nearest threat inside its radius at the given moment; empty when the radii
    /// are clear.
    func placeThreats(at date: Date) -> [NearestThreatSummary]

    /// Opens the places sheet: the radii and the home.
    func didTapPlaces()

    /// Opens the legend: what the map shows and that it is for information only.
    func didTapLegend()

    /// Closes any sheet and lets the user move the map under a centre pin to place the home or a place.
    func didStartPicking(_ pick: PlacePick)

    /// Follows the point under the centre of the map.
    func didChangeMapCenter(_ center: GeoCoordinate)

    /// Puts the place under the centre pin and leaves picking mode; a new place then waits for its name.
    func didConfirmPlacePick()

    func didCancelPlacePick()

    /// Names the place just added; a blank name keeps its locality.
    func didNamePlace(_ name: String)

    /// Flies to the user, asking for permission first if it was never asked.
    func didTapLocate()

    func didDismissLocationDeniedAlert()

    /// Moves the camera back onto the focused region.
    func didTapRecenter()

    /// Shows the whole country again.
    func didTapExitFocus()

    /// Opens the sheet of the tapped threat or region, or closes it when the tap hit neither.
    func didSelect(_ selection: MapSelection?)

    /// Flies to the threat named in a "near your place" banner and opens its sheet, as the feed does.
    func didTapPlaceThreatBanner(threatID: String)
}

/// Defines the routing capabilities for the Map flow.
protocol MapRouterProtocol: BaseRouterProtocol, SheetPresenting where SheetRoute == MapSheetRoute {

    /// Requests from other tabs, such as picking the home from the settings.
    var intentPublisher: AnyPublisher<MapIntent, Never> { get }
}

/// A protocol that defines the requirements for a Map flow factory.
protocol MapFactoryProtocol {
    associatedtype Sheet: View

    @ViewBuilder func sheet(for route: MapSheetRoute, actions: MapSheetActions) -> Sheet
}
