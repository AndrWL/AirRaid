//
//  BaseMapRestyler.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import MapLibre

/// Tweaks the downloaded base style so it recedes behind the alert layers.
///
/// Works on OpenMapTiles source layers and attributes (`place`, `poi`, `name:uk`), not on layer IDs: the dark style
/// names its labels `place_*`, the light ones `label_*`. A style with another schema simply keeps its own look.
enum BaseMapRestyler {

    /// Applies every tweak: hides admin lines and region names the app draws itself, switches names to Ukrainian
    /// in normal case, gives place names the map's label colours, on the dark style lightens roads it draws almost
    /// black, and recolours the detailed style dark when the palette asks for it.
    static func restyle(
        _ style: MLNStyle,
        palette: MapPalette
    ) {
        for identifier in Constants.hiddenLayerIDs {
            style.layer(withIdentifier: identifier)?.isVisible = false
        }
        if palette.darkensBasemap {
            BaseMapDarkener.darken(style)
        }
        for layer in style.layers {
            if let label = layer as? MLNSymbolStyleLayer {
                restyleLabel(label, palette: palette)
            } else if palette.restylesRoads, let road = layer as? MLNLineStyleLayer, road.identifier.hasPrefix(Constants.roadPrefix) {
                restyleRoad(road)
            }
        }
    }

    /// The base style's labels of things on land — countries, settlements, places of interest, airports, street
    /// names — whose filters the map narrows to Ukraine; seas and rivers keep their names.
    static func labelLayersInsideUkraine(in style: MLNStyle) -> [MLNSymbolStyleLayer] {
        style.layers
            .compactMap { $0 as? MLNSymbolStyleLayer }
            .filter { $0.isVisible && Constants.landSourceLayers.contains($0.sourceLayerIdentifier ?? "") }
    }

    /// Whether the layer labels the cities the map may also label itself.
    static func isCityLabel(_ layer: MLNSymbolStyleLayer) -> Bool {
        layer.sourceLayerIdentifier == Constants.placeSourceLayer && layer.identifier.contains(Constants.cityMarker)
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

    /// Names in Ukrainian instead of «Latin + local»; place names also in the map's colours.
    static func restyleLabel(
        _ label: MLNSymbolStyleLayer,
        palette: MapPalette
    ) {
        // Only the name labels: road shields and house numbers show other attributes.
        guard String(describing: label.text.mgl_jsonExpressionObject).contains(Constants.latinNameKey) else { return }
        // Built from style JSON: Foundation refuses custom functions such as `mgl_coalesce:` in format strings.
        label.text = NSExpression(mglJSONObject: [
            "coalesce",
            ["get", Constants.ukrainianNameKey],
            ["get", localNameKey]
        ])
        guard label.sourceLayerIdentifier == Constants.placeSourceLayer else { return }
        label.textTransform = NSExpression(forConstantValue: Constants.noTextTransform)
        // The style's grey names fade into the yellow and red alert fills; the map's own text on a contrasting halo
        // reads on any of them.
        label.textColor = NSExpression(forConstantValue: palette.label)
        label.textHaloColor = NSExpression(forConstantValue: palette.halo)
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
    /// Oblast borders and names, drawn by the map itself: the dark style's IDs, then the light ones'.
    static let hiddenLayerIDs = ["boundary_state", "place_state", "boundary_3", "label_state"]
    static let placeSourceLayer = "place"
    static let landSourceLayers: Set<String> = ["place", "poi", "aerodrome_label", "transportation_name"]
    /// In both `place_city_large` and `label_city_capital`.
    static let cityMarker = "city"
    static let latinNameKey = "name:latin"
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
