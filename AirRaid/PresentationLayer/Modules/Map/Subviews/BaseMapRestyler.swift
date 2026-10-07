//
//  BaseMapRestyler.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import MapLibre

/// Tweaks the downloaded base style so it recedes behind the alert layers.
///
/// Works on OpenMapTiles layer and attribute names (`place_*`, `highway_*`, `name:uk`); a style with
/// another schema simply keeps its own look.
enum BaseMapRestyler {

    /// Applies every tweak: hides admin lines and region names the app draws itself, switches place names
    /// to Ukrainian in normal case, and lightens roads that the dark style draws almost black.
    static func restyle(_ style: MLNStyle) {
        for identifier in Constants.hiddenLayerIDs {
            style.layer(withIdentifier: identifier)?.isVisible = false
        }
        for layer in style.layers {
            if let label = layer as? MLNSymbolStyleLayer, label.identifier.hasPrefix(Constants.placeLabelPrefix) {
                restylePlaceLabel(label)
            } else if let road = layer as? MLNLineStyleLayer, road.identifier.hasPrefix(Constants.roadPrefix) {
                restyleRoad(road)
            }
        }
    }

    /// The base style's city label layers, whose filters the map extends to avoid duplicate labels.
    static func cityLabelLayers(in style: MLNStyle) -> [MLNSymbolStyleLayer] {
        Constants.cityLabelLayerIDs.compactMap { style.layer(withIdentifier: $0) as? MLNSymbolStyleLayer }
    }

    /// The attribute holding a place's local name — Ukrainian for places in Ukraine.
    static let localNameKey = "name"
}

// MARK: - Private methods

private extension BaseMapRestyler {

    static func restylePlaceLabel(_ label: MLNSymbolStyleLayer) {
        label.text = NSExpression(format: "mgl_coalesce({%K, %K})", Constants.ukrainianNameKey, localNameKey)
        label.textTransform = NSExpression(forConstantValue: Constants.noTextTransform)
        if Constants.cityLabelLayerIDs.contains(label.identifier) {
            label.textColor = NSExpression(forConstantValue: UIColor.white)
        }
    }

    /// Casings stay dark so the light road keeps an edge against the fills.
    static func restyleRoad(_ road: MLNLineStyleLayer) {
        let isCasing = road.identifier.hasSuffix(Constants.casingSuffix)
        road.lineColor = NSExpression(forConstantValue: isCasing ? Constants.roadCasingColor : Constants.roadColor)
        road.lineOpacity = NSExpression(forConstantValue: Constants.roadOpacity)
        // The low-zoom "subtle" roads start at zero width; a fixed hairline keeps highways visible at oblast zoom.
        if road.identifier.hasSuffix(Constants.subtleSuffix) {
            road.lineWidth = NSExpression(forConstantValue: Constants.subtleRoadWidth)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let hiddenLayerIDs = ["boundary_state", "place_state"]
    static let cityLabelLayerIDs = ["place_city", "place_city_large"]
    static let placeLabelPrefix = "place_"
    static let roadPrefix = "highway_"
    static let casingSuffix = "_casing"
    static let subtleSuffix = "_subtle"
    static let ukrainianNameKey = "name:uk"
    static let noTextTransform = "none"

    static let roadColor = UIColor(white: 0.75, alpha: 1)
    static let roadCasingColor = UIColor(white: 0.2, alpha: 1)
    static let roadOpacity: Double = 0.7
    static let subtleRoadWidth: Double = 1
}
