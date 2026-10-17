//
//  EntitlementServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine

/// Whether the user has AirRaid Плюс, kept current with the App Store.
protocol EntitlementServiceProtocol {

    /// Emits on subscription and on every change: a purchase, a renewal, an expiry, a refund.
    var isPlusActivePublisher: AnyPublisher<Bool, Never> { get }

    /// Starts listening for transactions. Idempotent; call once at launch so no renewal is missed.
    func start()

    /// Asks the App Store for the user's purchases again — «Відновити покупки».
    ///
    /// - Throws: ``RestorePurchasesError/cancelled`` when the user cancels the sign-in, or another error when the
    ///   App Store cannot be reached.
    func restorePurchases() async throws

    /// Whether the App Store offers any of the Плюс subscriptions here and now; `false` offline, in a storefront
    /// without them, or when the request fails.
    func areProductsAvailable() async -> Bool
}
