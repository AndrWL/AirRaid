//
//  PlaceEditorProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Defines the state of a saved place's screen in the settings: its name, radius, and moving or removing it.
protocol PlaceEditorViewModelProtocol: BaseViewModelProtocol {

    /// The place as it is now, or `nil` once it has been removed.
    var place: SettingsPlaceContent? { get }

    /// The radii to pick from, in kilometres.
    var radiusOptions: [Double] { get }

    /// The name being typed; only a custom place has one.
    var name: String { get set }

    /// What the name field shows while empty: the locality the place goes by without a name.
    var namePlaceholder: String { get }

    /// Loads the outlines that name the place's region. Safe to call on every appearance.
    func onAppear() async

    /// Saves the typed name; a blank one falls back to the locality.
    func didCommitName()

    func didSelectRadius(_ radiusKm: Double)

    /// Switches to the map with this place under the centre pin.
    func didTapMoveOnMap()

    /// Removes the place and goes back to the settings.
    func didConfirmRemove()
}

/// Defines the routing capabilities of a saved place's screen.
protocol PlaceEditorRouterProtocol: BaseRouterProtocol {

    func showPlacePickerOnMap(_ pick: PlacePick)

    /// Back to the settings, once the place is gone.
    func close()
}
