//
//  FocusedRegionRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import Foundation

/// Keeps the focused region in `UserDefaults`, so the map opens on it after a relaunch.
final class FocusedRegionRepository {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let subject: CurrentValueSubject<String?, Never>

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.subject = CurrentValueSubject(defaults.string(forKey: Constants.key))
    }
}

// MARK: - FocusedRegionRepositoryProtocol

extension FocusedRegionRepository: FocusedRegionRepositoryProtocol {

    var focusedRegionIDPublisher: AnyPublisher<String?, Never> {
        subject.eraseToAnyPublisher()
    }

    func setFocusedRegion(_ regionID: String?) {
        guard regionID != subject.value else { return }
        defaults.set(regionID, forKey: Constants.key)
        subject.send(regionID)
    }
}

// MARK: - Constants

private enum Constants {
    static let key = "focusedRegionID"
}
