//
//  MiniMapView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The home's oblast with its alerted raions and the home pin, in the map's colours.
struct MiniMapView: View {

    // MARK: - Variables

    let map: MiniMap

    var body: some View {
        ZStack {
            ForEach(Array(map.areas.enumerated()), id: \.offset) { index, area in
                // The first area is the oblast: its outline is the bold one.
                let shape = MiniMapAreaShape(area: area)
                shape
                    .fill(fill(of: area), style: FillStyle(eoFill: true))
                    .overlay {
                        shape.stroke(
                            Color.mapOutline.opacity(Constants.outlineOpacity),
                            lineWidth: index == 0 ? Constants.outlineWidth : Constants.raionLineWidth
                        )
                    }
            }
            GeometryReader { proxy in
                Circle()
                    .fill(Color.mapHome)
                    .overlay { Circle().stroke(Color.white, lineWidth: Constants.pinRimWidth) }
                    .frame(width: Constants.pinSize, height: Constants.pinSize)
                    .position(x: map.home.x * proxy.size.width, y: map.home.y * proxy.size.height)
            }
        }
        .aspectRatio(map.aspectRatio, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// MARK: - Private methods

private extension MiniMapView {

    /// Every area is land, so a quiet one gets the territory colour: an enclave such as Kyiv must not read as a hole.
    func fill(of area: MiniMapArea) -> Color {
        switch area.fill {
        case .none: return .mapTerritory
        case .red: return .mapAlertRed.opacity(Constants.wholeOpacity)
        case .yellow: return .mapAlertYellow.opacity(Constants.wholeOpacity)
        case .redPartial: return .mapAlertRed.opacity(Constants.partialOpacity)
        case .yellowPartial: return .mapAlertYellow.opacity(Constants.partialOpacity)
        }
    }
}

// MARK: - MiniMapAreaShape

/// The rings of one area scaled into the frame; holes are cut by the even-odd fill.
nonisolated private struct MiniMapAreaShape: Shape {

    let area: MiniMapArea

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for ring in area.rings where ring.count >= Constants.minRingPoints {
            path.addLines(ring.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let outlineWidth: CGFloat = 1
    static let raionLineWidth: CGFloat = 0.5
    /// Over the territory colour, like the map's alert fill.
    static let wholeOpacity: Double = 0.85
    static let outlineOpacity: Double = 0.6
    /// The map's pale fill for a raion where only a hromada is alerted.
    static let partialOpacity: Double = 0.4
    static let pinSize: CGFloat = 8
    static let pinRimWidth: CGFloat = 1.5
    static let minRingPoints = 3
}
