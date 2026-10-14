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
    /// - Throws: When the App Store cannot be reached or the user cancels the sign-in.
    func restorePurchases() async throws
}
