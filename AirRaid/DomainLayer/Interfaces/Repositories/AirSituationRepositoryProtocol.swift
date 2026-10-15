//
//  AirSituationRepositoryProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine

/// Provides the live air situation: active alerts and spotted threats.
protocol AirSituationRepositoryProtocol {

    /// Emits the current situation on subscription and every change after it.
    var situationPublisher: AnyPublisher<AirSituation, Never> { get }

    /// Emits the changes behind each new situation, in the order they were applied; nothing on subscription.
    ///
    /// A snapshot (on connect or after a server restart) is turned into the changes against the state before it, so
    /// the first snapshot reports every threat and alert as new.
    var eventsPublisher: AnyPublisher<[AirSituationEvent], Never> { get }
}
