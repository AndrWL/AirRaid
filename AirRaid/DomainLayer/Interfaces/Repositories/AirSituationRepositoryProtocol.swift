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
}
