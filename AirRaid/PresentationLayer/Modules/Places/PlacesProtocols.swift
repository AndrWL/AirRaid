//
//  PlacesProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Foundation

/// Defines the state of the places sheet: the user's location and home, and the radius watched around each.
protocol PlacesViewModelProtocol: BaseViewModelProtocol {

    /// The radii to pick from, in kilometres.
    var radiusOptions: [Double] { get }

    /// Whether the app may read the user's location.
    var locationAuthorization: LocationAuthorization { get }

    var currentLocationRadiusKm: Double { get }

    /// The home's radius, or `nil` while no home is set.
    var homeRadiusKm: Double? { get }

    /// The home's id, or `nil` while no home is set.
    var homeID: SavedPlace.ID? { get }

    /// The oblast the home pin is in; `nil` without a home or outside Ukraine.
    var homeRegionName: String? { get }

    /// The custom places, each with its radius; empty without Plus (they are paused, not lost).
    var customPlaces: [SavedPlace] { get }

    /// Whether the user's location is known, so the home can be put there.
    var canUseCurrentLocation: Bool { get }

    /// Loads the region outlines to name the home's region. Safe to call on every appearance.
    func onAppear() async

    func didSelectCurrentLocationRadius(_ radiusKm: Double)

    func didSelectRadius(_ radiusKm: Double, forPlace id: SavedPlace.ID)

    func didTapRemoveHome()

    /// Puts the home where the user is now.
    func didTapUseCurrentLocation()
}
