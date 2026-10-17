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
    /// to Ukrainian in normal case and the map's label colours, and lightens roads that the dark style draws almost
    /// black.
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

    /// The base style's place labels — countries, cities, towns, villages — whose filters the map narrows to Ukraine
    /// and, for cities, to the ones it does not label itself.
    static func placeLabelLayers(in style: MLNStyle) -> [MLNSymbolStyleLayer] {
        style.layers
            .compactMap { $0 as? MLNSymbolStyleLayer }
            .filter { $0.identifier.hasPrefix(Constants.placeLabelPrefix) }
    }

    /// Whether the layer labels the cities the map may also label itself.
    static func isCityLabel(_ layer: MLNSymbolStyleLayer) -> Bool {
        Constants.cityLabelLayerIDs.contains(layer.identifier)
    }

    /// A style filter passing only features inside the polygons, as a JSON expression: `within` has no `NSPredicate`
    /// form.
    static func withinExpression(_ polygons: [GeoPolygon]) -> [Any] {
        let coordinates = polygons.map { polygon in
            ([polygon.exterior] + polygon.holes).map { ring in
                // GeoJSON rings are closed: the first point repeats at the end.
                (ring + ring.prefix(ring.first == ring.last ? 0 : 1)).map { [$0.longitude, $0.latitude] }
            }
        }
        return ["within", ["type": "MultiPolygon", "coordinates": coordinates] as [String: Any]]
    }

    /// The attribute holding a place's local name — Ukrainian for places in Ukraine.
    static let localNameKey = "name"
}

// MARK: - Private methods

private extension BaseMapRestyler {

    static func restylePlaceLabel(_ label: MLNSymbolStyleLayer) {
        // Built from style JSON: Foundation refuses custom functions such as `mgl_coalesce:` in format strings.
        label.text = NSExpression(mglJSONObject: [
            "coalesce",
            ["get", Constants.ukrainianNameKey],
            ["get", localNameKey]
        ])
        label.textTransform = NSExpression(forConstantValue: Constants.noTextTransform)
        // The style's grey names fade into the yellow and red alert fills; the map's own light text on a dark halo
        // reads on any of them.
        label.textColor = NSExpression(forConstantValue: UIColor.mapLabel)
        label.textHaloColor = NSExpression(forConstantValue: UIColor.mapHalo)
        label.textHaloWidth = NSExpression(forConstantValue: MapLayerStyle.cityHaloWidth)
        label.textHaloBlur = NSExpression(forConstantValue: 0)
        // A step behind the map's own labels: the regional centres and threat captions stay the brightest.
        label.textOpacity = NSExpression(forConstantValue: Constants.placeLabelOpacity)
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
    static let placeLabelOpacity: Double = 0.8

    static let roadColor = UIColor(white: 0.75, alpha: 1)
    static let roadCasingColor = UIColor(white: 0.2, alpha: 1)
    static let roadOpacity: Double = 0.7
    static let subtleRoadWidth: Double = 1
}
