//
//  PaywallView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import StoreKit
import SwiftUI

/// The AirRaid Plus sheet: the features, then StoreKit's own store view with prices from the App Store.
struct PaywallView<ViewModel: PaywallViewModelProtocol>: View {

    // MARK: - Variables

    private let viewModel: ViewModel
    private let onClose: () -> Void

    init(
        viewModel: ViewModel,
        onClose: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    var body: some View {
        Group {
            if viewModel.isPlusActive {
                activeState
            } else {
                switch viewModel.areProductsAvailable {
                case true?: store
                case false?: unavailableState
                case nil: loadingState
                }
            }
        }
        .background(Color.appBackground)
        .task { await viewModel.loadProducts() }
        .overlay(alignment: .topTrailing) {
            CloseButton(action: onClose)
                .padding(Spacing.large)
        }
    }
}

// MARK: - Sections

private extension PaywallView {

    var store: some View {
        SubscriptionStoreView(productIDs: viewModel.productIDs) {
            ScrollView {
                PlusFeatureList()
                    .padding(Spacing.large)
                    .padding(.top, Spacing.xxLarge)
            }
        }
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.hidden, for: .cancellation)
        .safeAreaInset(edge: .bottom) {
            restore
        }
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success) = result {
                onClose()
            }
        }
    }

    var restore: some View {
        VStack(spacing: Spacing.xSmall) {
            Button {
                Task { await viewModel.didTapRestore() }
            } label: {
                if viewModel.isRestoring {
                    ProgressView()
                } else {
                    Text("Відновити покупки")
                }
            }
            .font(.app(.footnote, weight: .semibold))
            .disabled(viewModel.isRestoring)
            if let restoreErrorText = viewModel.restoreErrorText {
                Text(restoreErrorText)
                    .font(.app(.footnote))
                    .foregroundStyle(.warningInk)
            }
        }
        .padding(.bottom, Spacing.small)
    }

    /// StoreKit's own fallback is in English and hides the features, so this one says what Plus gives and why it
    /// cannot be bought right now.
    var unavailableState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                PlusFeatureList()
                InlineNote(
                    "Підписка зараз недоступна в App Store. Перевірте з'єднання і спробуйте пізніше.",
                    systemImage: "exclamationmark.triangle",
                    tone: .warning
                )
                Button("Спробувати ще раз") {
                    Task { await viewModel.loadProducts() }
                }
                .font(.app(.body, weight: .semibold))
                .frame(maxWidth: .infinity)
            }
            .padding(Spacing.large)
            .padding(.top, Spacing.xxLarge)
        }
        .safeAreaInset(edge: .bottom) {
            restore
        }
    }

    var loadingState: some View {
        ScrollView {
            PlusFeatureList()
                .padding(Spacing.large)
                .padding(.top, Spacing.xxLarge)
            ProgressView()
                .padding(Spacing.large)
        }
    }

    var activeState: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: Constants.sealSize))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("AirRaid Плюс активний")
                .font(.app(.title2, weight: .bold))
                .foregroundStyle(.ink)
            Text("Дякуємо, що підтримуєте проєкт.")
                .font(.app(.body))
                .foregroundStyle(.inkMuted)
            PlusFeatureList()
                .padding(.top, Spacing.medium)
        }
        .padding(Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Constants

private enum Constants {
    static let sealSize: CGFloat = 56
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return PaywallCoordinatorView(appContainer: container)
}
