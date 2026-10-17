//
//  PlacePickerOverlay.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// Place-picking mode over the map: the place's pin fixed at the centre, and a panel to confirm or cancel. The user
/// moves the map under the pin instead of aiming a finger at a small point.
struct PlacePickerOverlay: View {

    // MARK: - Variables

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let pick: PlacePick

    /// Whether a home is set, so picking the home says "move" instead of "set".
    let hasHome: Bool
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

private extension PlacePickerOverlay {

    /// The pin's tip sits on the exact centre of the map, the point that becomes the place.
    var centerPin: some View {
        VStack(spacing: 0) {
            Image(systemName: isHome ? "house.circle.fill" : "mappin.circle.fill")
                .font(.system(size: Constants.pinSize))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, tint)
                .shadow(radius: Constants.pinShadow)
            Rectangle()
                .fill(tint)
                .frame(width: Constants.stemWidth, height: Constants.stemHeight)
            Circle()
                .fill(tint)
                .frame(width: Constants.tipSize, height: Constants.tipSize)
        }
        // Lift the pin by its own height minus half the tip, so the tip's centre is the screen's centre.
        .offset(y: -(Constants.pinSize + Constants.stemHeight) / 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    var panel: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(title)
                .font(.app(.headline, weight: .semibold))
                .foregroundStyle(.ink)
            Text(isHome ? "Дім буде там, де вказує пін у центрі." : "Місце буде там, де вказує пін у центрі.")
                .font(.app(.footnote))
                .foregroundStyle(.inkMuted)
            HStack(spacing: Spacing.small) {
                Button(action: onCancel) {
                    Text("Скасувати")
                        .frame(maxWidth: .infinity)
                }
                .glassButtonStyle()
                Button(action: onConfirm) {
                    Text(isHome ? "Тут мій дім" : "Тут")
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

    var isHome: Bool {
        pick == .home
    }

    var tint: Color {
        isHome ? .mapHome : .mapSavedPlace
    }

    var title: String {
        switch pick {
        case .home: hasHome ? "Перемістіть мапу, щоб змінити дім" : "Перемістіть мапу, щоб поставити дім"
        case .newPlace: "Перемістіть мапу, щоб додати місце"
        case .move: "Перемістіть мапу, щоб змінити місце"
        }
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
    PlacePickerOverlay(pick: .newPlace, hasHome: true, onConfirm: {}, onCancel: {})
        .background(.black)
        .preferredColorScheme(.dark)
}
