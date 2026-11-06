//
//  PaywallViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation

/// The view model of the AirRaid Plus sheet. The purchase itself is StoreKit's store view; this follows the result.
@Observable
final class PaywallViewModel: BaseViewModel {

    // MARK: - Variables

    let productIDs: [String]
    private(set) var isPlusActive = false
    private(set) var isRestoring = false
    private(set) var restoreErrorText: String?
    private(set) var areProductsAvailable: Bool?

    @ObservationIgnored
    private let entitlementService: EntitlementServiceProtocol

    init(
        entitlementService: EntitlementServiceProtocol,
        productIDs: [String]
    ) {
        self.entitlementService = entitlementService
        self.productIDs = productIDs
        super.init()
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        entitlementService.isPlusActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.isPlusActive = isActive
            }
            .store(in: &cancellables)
    }
}

// MARK: - PaywallViewModelProtocol

extension PaywallViewModel: PaywallViewModelProtocol {

    func loadProducts() async {
        areProductsAvailable = await entitlementService.areProductsAvailable()
    }

    func didTapRestore() async {
        isRestoring = true
        restoreErrorText = nil
        defer { isRestoring = false }
        do {
            try await entitlementService.restorePurchases()
            if !isPlusActive {
                restoreErrorText = "Активної підписки не знайдено."
            }
        } catch RestorePurchasesError.cancelled {
            // The user closed the sign-in themselves.
        } catch {
            restoreErrorText = "Не вдалося зв'язатися з App Store. Спробуйте пізніше."
        }
    }
}
