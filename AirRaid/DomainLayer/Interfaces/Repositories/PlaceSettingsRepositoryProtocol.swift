//
//  PlaceSettingsRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation

/// Keeps the saved places and the radius around each watched place.
///
/// It stores what it is given: how many places the user may have is the caller's check against ``PremiumLimits``.
protocol PlaceSettingsRepositoryProtocol {

    /// Emits the current settings on subscription and every change after it.
    var settingsPublisher: AnyPublisher<PlaceSettings, Never> { get }

    /// Drops the home pin here, keeping its radius if it was set before.
    func setHome(at coordinate: GeoCoordinate)

    /// Adds a custom place with the default radius.
    ///
    /// - Parameter name: The user's name for it; `nil` names it by its locality.
    @discardableResult
    func addPlace(at coordinate: GeoCoordinate, name: String?) -> SavedPlace.ID

    /// Moves a saved place, keeping its name and radius; its address is looked up again.
    func movePlace(_ id: SavedPlace.ID, to coordinate: GeoCoordinate)

    /// Renames a custom place; `nil` or a blank name falls back to its locality. Does nothing for the home.
    func renamePlace(_ id: SavedPlace.ID, to name: String?)

    func setRadius(_ radiusKm: Double, forPlace id: SavedPlace.ID)

    func setCurrentLocationRadius(_ radiusKm: Double)

    func removePlace(_ id: SavedPlace.ID)
}
