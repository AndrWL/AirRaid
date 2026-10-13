//
//  HomeDetailsProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// Defines the state of the home sheet: the home, followed live with the alerts and threats around it.
protocol HomeDetailsViewModelProtocol: BaseViewModelProtocol {

    /// The radii to pick from, in kilometres.
    var radiusOptions: [Double] { get }

    /// The home's radius, or `nil` once the home has been removed.
    var radiusKm: Double? { get }

    /// The sheet's content at the given moment, or `nil` once the home has been removed.
    func content(at date: Date) -> HomeDetailsContent?

    /// Loads the outlines that place the home in its oblast and raion. Safe to call on every appearance.
    func onAppear() async

    func didSelectRadius(_ radiusKm: Double)

    func didTapRemoveHome()
}
