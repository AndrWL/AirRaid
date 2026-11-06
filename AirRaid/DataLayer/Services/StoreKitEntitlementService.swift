//
//  StoreKitEntitlementService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation
import OSLog
import StoreKit

/// AirRaid Plus from StoreKit 2: the current entitlements at launch, then every transaction as it comes.
///
/// Checked on the device only, from transactions StoreKit has already verified (JWS). Enough for convenience
/// features; anything the server would serve to subscribers only will need the App Store Server API there.
final class StoreKitEntitlementService {

    // MARK: - Variables

    private let productIDs: Set<String>
    private let subject = CurrentValueSubject<Bool, Never>(false)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var updatesTask: Task<Void, Never>?

    /// - Parameter productIDs: The subscriptions that unlock Plus.
    init(productIDs: Set<String>) {
        self.productIDs = productIDs
    }

    deinit {
        updatesTask?.cancel()
    }
}

// MARK: - EntitlementServiceProtocol

extension StoreKitEntitlementService: EntitlementServiceProtocol {

    var isPlusActivePublisher: AnyPublisher<Bool, Never> {
        subject.removeDuplicates().eraseToAnyPublisher()
    }

    func start() {
        guard updatesTask == nil else { return }
        // Renewals, refunds and purchases made on another device or from the paywall arrive here.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            throw RestorePurchasesError.cancelled
        }
        await refresh()
    }

    func areProductsAvailable() async -> Bool {
        do {
            return try await !Product.products(for: productIDs).isEmpty
        } catch {
            logger.error("Failed to load products: \(String(describing: error), privacy: .public)")
            return false
        }
    }
}

// MARK: - Private methods

private extension StoreKitEntitlementService {

    func refresh() async {
        var isActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate < .now {
                continue
            }
            isActive = true
        }
        logger.info("Плюс \(isActive ? "active" : "inactive", privacy: .public)")
        subject.send(isActive)
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Entitlements"
}
