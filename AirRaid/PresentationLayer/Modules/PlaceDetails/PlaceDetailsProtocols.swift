//
//  PlaceDetailsProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// Defines the state of a saved place's sheet: the place, followed live with the alerts and threats around it.
protocol PlaceDetailsViewModelProtocol: BaseViewModelProtocol {

    /// The radii to pick from, in kilometres.
    var radiusOptions: [Double] { get }

    /// The place's radius, or `nil` once the place has been removed.
    var radiusKm: Double? { get }

    /// What moving the place on the map means: the home's pick, or this place's.
    var pick: PlacePick { get }

    /// The sheet's content at the given moment, or `nil` once the place has been removed.
    func content(at date: Date) -> PlaceDetailsContent?

    /// Loads the outlines that place it in its oblast and raion. Safe to call on every appearance.
    func onAppear() async

    func didSelectRadius(_ radiusKm: Double)

    func didTapRemove()
}
