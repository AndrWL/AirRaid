//
//  FavoriteRegionsRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation

/// Keeps the followed regions in `UserDefaults`: a handful of ISO codes, nothing sensitive.
final class FavoriteRegionsRepository {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let subject: CurrentValueSubject<[String], Never>

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.subject = CurrentValueSubject(defaults.stringArray(forKey: Constants.key) ?? [])
    }
}

// MARK: - FavoriteRegionsRepositoryProtocol

extension FavoriteRegionsRepository: FavoriteRegionsRepositoryProtocol {

    var favoriteRegionIDsPublisher: AnyPublisher<[String], Never> {
        subject.eraseToAnyPublisher()
    }

    func setFavorite(_ isFavorite: Bool, regionID: String) {
        var ids = subject.value
        if isFavorite {
            guard !ids.contains(regionID) else { return }
            ids.append(regionID)
        } else {
            guard ids.contains(regionID) else { return }
            ids.removeAll { $0 == regionID }
        }
        defaults.set(ids, forKey: Constants.key)
        subject.send(ids)
    }
}

// MARK: - Constants

private enum Constants {
    static let key = "favoriteRegionIDs"
}
