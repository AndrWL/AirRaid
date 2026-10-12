//
//  FavoriteRegionsRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine

/// The regions the user follows: pinned on the map, and later the ones they get notified about.
protocol FavoriteRegionsRepositoryProtocol {

    /// ISO 3166-2 codes of the followed regions in the order they were added; emits the current list on subscription
    /// and every change after it.
    var favoriteRegionIDsPublisher: AnyPublisher<[String], Never> { get }

    /// Follows or unfollows the region.
    func setFavorite(_ isFavorite: Bool, regionID: String)
}
