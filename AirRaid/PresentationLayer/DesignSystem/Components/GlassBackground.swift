//
//  GlassBackground.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

// MARK: - View

extension View {

    /// Puts the view on glass over the map: Liquid Glass on iOS 26, a regular material before it.
    ///
    /// The one place the fallback lives, so screens never branch on the OS version for it.
    @ViewBuilder
    func glassBackground<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    /// The glass button style on iOS 26, a bordered button before it.
    @ViewBuilder
    func glassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}
