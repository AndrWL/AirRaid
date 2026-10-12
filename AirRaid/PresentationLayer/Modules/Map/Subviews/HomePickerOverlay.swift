//
//  HomePickerOverlay.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// Home-picking mode over the map: a house pin fixed at the centre, and a panel to confirm or cancel. The user moves
/// the map under the pin instead of aiming a finger at a small point.
struct HomePickerOverlay: View {

    // MARK: - Variables

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isMovingHome: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            centerPin
            VStack {
                Spacer()
                panel
            }
        }
    }
}

// MARK: - Private methods

private extension HomePickerOverlay {

    /// The pin's tip sits on the exact centre of the map, the point that becomes the home.
    var centerPin: some View {
        VStack(spacing: 0) {
            Image(systemName: "house.circle.fill")
                .font(.system(size: Constants.pinSize))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.accentColor)
                .shadow(radius: Constants.pinShadow)
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: Constants.stemWidth, height: Constants.stemHeight)
            Circle()
                .fill(Color.accentColor)
                .frame(width: Constants.tipSize, height: Constants.tipSize)
        }
        // Lift the pin by its own height minus half the tip, so the tip's centre is the screen's centre.
        .offset(y: -(Constants.pinSize + Constants.stemHeight) / 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    var panel: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(isMovingHome ? "Перемістіть карту, щоб змінити дім" : "Перемістіть карту, щоб поставити дім")
                .font(.app(.headline, weight: .semibold))
                .foregroundStyle(.ink)
            Text("Дім буде там, де вказує пін по центру.")
                .font(.app(.footnote))
                .foregroundStyle(.inkMuted)
            HStack(spacing: Spacing.small) {
                Button(action: onCancel) {
                    Text("Скасувати")
                        .frame(maxWidth: .infinity)
                }
                .glassButtonStyle()
                Button(action: onConfirm) {
                    Text("Тут мій дім")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .font(.app(.body, weight: .semibold))
            .controlSize(.large)
        }
        .padding(Spacing.large)
        .glassBackground(in: .rect(cornerRadius: Radius.large))
        .contentShape(.rect(cornerRadius: Radius.large))
        .padding(.horizontal, Spacing.large)
        .padding(.bottom, Constants.panelBottomInset)
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Constants

private enum Constants {
    static let pinSize: CGFloat = 40
    static let pinShadow: CGFloat = 4
    static let stemWidth: CGFloat = 3
    static let stemHeight: CGFloat = 10
    static let tipSize: CGFloat = 6
    /// Clears the floating tab bar.
    static let panelBottomInset: CGFloat = 100
}

#Preview {
    HomePickerOverlay(isMovingHome: false, onConfirm: {}, onCancel: {})
        .background(.black)
        .preferredColorScheme(.dark)
}
