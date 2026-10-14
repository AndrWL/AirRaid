//
//  HomeStatusBroadcasting.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Combine
import HomeStatusKit

/// Keeps the surfaces outside the app — the home screen widgets and the Live Activity — in step with the home's status.
protocol HomeStatusBroadcasting {

    /// The status the widgets show, for screens inside the app; `nil` without a place. Emits on subscription.
    var statusPublisher: AnyPublisher<HomeStatus?, Never> { get }

    /// Starts following the situation and the home. Idempotent; runs for the rest of the session.
    func start()
}
