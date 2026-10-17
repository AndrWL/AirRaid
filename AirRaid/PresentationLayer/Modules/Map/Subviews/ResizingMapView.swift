//
//  ResizingMapView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 16.10.2026.
//

import MapLibre

/// A map view that reports when its size changes, so a camera fitted to its old size can be fitted again.
///
/// SwiftUI may lay the view out more than once while the app starts (the splash, the tab bar, a launch in the
/// background), and a fit made at the first size stays wrong for the final one.
final class ResizingMapView: MLNMapView {

    // MARK: - Variables

    var onResize: (() -> Void)?

    private var lastSize: CGSize = .zero

    // MARK: - Override methods

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastSize else { return }
        lastSize = bounds.size
        onResize?()
    }
}
