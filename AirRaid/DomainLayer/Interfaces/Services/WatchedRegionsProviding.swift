//
//  WatchedRegionsProviding.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine

/// The oblasts of the user's watched places for the «Мої місця» filter.
protocol WatchedRegionsProviding {

    /// ISO 3166-2 codes; empty while no place is known. Emits on subscription and after every change.
    var regionIDsPublisher: AnyPublisher<Set<String>, Never> { get }
}
