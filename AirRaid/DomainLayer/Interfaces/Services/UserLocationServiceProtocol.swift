//
//  UserLocationServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine

/// The user's location while the app is in use: for the blue dot, the distance to threats and the "to me" button.
protocol UserLocationServiceProtocol {

    /// Emits the current authorization on subscription and every change after it.
    var authorizationPublisher: AnyPublisher<LocationAuthorization, Never> { get }

    /// The latest known location, or `nil` before the first fix or without permission; emits on subscription.
    var locationPublisher: AnyPublisher<GeoCoordinate?, Never> { get }

    /// Shows the system permission prompt; does nothing once the user has answered it.
    func requestAuthorization()
}
