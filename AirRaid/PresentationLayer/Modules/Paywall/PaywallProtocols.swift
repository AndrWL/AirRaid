//
//  PaywallProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Defines the state of the AirRaid Плюс sheet.
protocol PaywallViewModelProtocol: BaseViewModelProtocol {

    /// The subscriptions the store view offers.
    var productIDs: [String] { get }

    var isPlusActive: Bool { get }

    var isRestoring: Bool { get }

    /// Shown under the restore button when the App Store could not be reached.
    var restoreErrorText: String? { get }

    /// Whether the App Store has the subscriptions to sell; until it answers, `nil`.
    var areProductsAvailable: Bool? { get }

    /// Asks the App Store whether the subscriptions can be bought, so an empty store gets an explanation in Ukrainian
    /// instead of StoreKit's own placeholder.
    func loadProducts() async

    func didTapRestore() async
}
