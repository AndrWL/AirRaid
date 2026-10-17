//
//  MapPalette.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 17.10.2026.
//

import UIKit

/// The colours of the map's own layers — labels, outlines, the track — that depend on whether the base map is dark
/// or light. The alert fills and the places' colours read on both and stay the same.
struct MapPalette: Equatable {

    // MARK: - Variables

    let label: UIColor
    let halo: UIColor
    let caption: UIColor
    let territory: UIColor
    let territoryOpacity: Double
    let outline: UIColor
    let track: UIColor
    let focusDim: UIColor

    /// The dark style draws roads almost black, so they are lightened; the light styles keep their own.
    let restylesRoads: Bool

    /// The detailed style is light; its land, water, buildings and roads are recoloured dark on the device.
    let darkensBasemap: Bool

    init(_ style: MapBaseStyle) {
        switch style {
        case .dark: self = .dark
        case .detailedDark: self = .darkDetailed
        case .light, .detailed: self = .light
        }
    }

    private init(
        label: UIColor,
        halo: UIColor,
        caption: UIColor,
        territory: UIColor,
        territoryOpacity: Double,
        outline: UIColor,
        track: UIColor,
        focusDim: UIColor,
        restylesRoads: Bool,
        darkensBasemap: Bool = false
    ) {
        self.label = label
        self.halo = halo
        self.caption = caption
        self.territory = territory
        self.territoryOpacity = territoryOpacity
        self.outline = outline
        self.track = track
        self.focusDim = focusDim
        self.restylesRoads = restylesRoads
        self.darkensBasemap = darkensBasemap
    }
}

// MARK: - Palettes

private extension MapPalette {

    /// Light text on a dark halo, white lines.
    static let dark = MapPalette(
        label: .mapLabel,
        halo: .mapHalo,
        caption: .mapCaption,
        territory: .mapTerritory,
        territoryOpacity: 0.55,
        outline: .mapOutline,
        track: .mapTrack,
        focusDim: .mapDim,
        restylesRoads: true
    )

    /// The dark palette over the detailed style recoloured dark; its roads are recoloured with the rest.
    static let darkDetailed = MapPalette(
        label: .mapLabel,
        halo: .mapHalo,
        caption: .mapCaption,
        territory: .mapTerritory,
        territoryOpacity: 0.4,
        outline: .mapOutline,
        track: .mapTrack,
        focusDim: .mapDim,
        restylesRoads: false,
        darkensBasemap: true
    )

    /// Dark text on a light halo, dark lines; a paler territory tint and a light veil outside the focus.
    static let light = MapPalette(
        label: .mapLabelLight,
        halo: .mapHaloLight,
        caption: .mapCaptionLight,
        territory: .mapTerritoryLight,
        territoryOpacity: 0.45,
        outline: .mapOutlineLight,
        track: .mapTrackLight,
        focusDim: .mapDimLight,
        restylesRoads: false
    )
}
