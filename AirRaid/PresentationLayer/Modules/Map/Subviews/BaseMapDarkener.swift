//
//  BaseMapDarkener.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 17.10.2026.
//

import MapLibre

/// Recolours a light OpenMapTiles style dark on the device, for the detailed map in the system's dark appearance.
///
/// OpenFreeMap has no dark detailed style, so `liberty` keeps its forests, water, buildings and roads, in dark
/// colours. Matched by layer type and OpenMapTiles source layer, a dozen rules instead of a hundred layer IDs.
enum BaseMapDarkener {

    static func darken(_ style: MLNStyle) {
        for layer in style.layers {
            switch layer {
            case let background as MLNBackgroundStyleLayer:
                background.backgroundColor = NSExpression(forConstantValue: UIColor.mapDarkLand)
            case let raster as MLNRasterStyleLayer:
                // The Natural Earth relief under the vector land: kept as a faint texture.
                raster.maximumRasterBrightness = NSExpression(forConstantValue: Constants.reliefBrightness)
            case let extrusion as MLNFillExtrusionStyleLayer:
                extrusion.fillExtrusionColor = NSExpression(forConstantValue: UIColor.mapDarkBuilding)
            case let fill as MLNFillStyleLayer:
                darken(fill)
            case let line as MLNLineStyleLayer:
                darken(line)
            case let label as MLNSymbolStyleLayer:
                darken(label)
            default:
                break
            }
        }
    }
}

// MARK: - Private methods

private extension BaseMapDarkener {

    static func darken(_ fill: MLNFillStyleLayer) {
        let color: UIColor
        switch fill.sourceLayerIdentifier {
        case "water":
            color = .mapDarkWater
        case "park":
            color = .mapDarkVegetation
        case "landcover":
            color = fill.identifier.contains("ice") || fill.identifier.contains("sand")
                ? Constants.bareLandColor
                : .mapDarkVegetation
        case "building":
            color = .mapDarkBuilding
        case "transportation":
            // The pedestrian-area hatching would stay a light pattern on the dark land.
            fill.isVisible = false
            return
        default:
            color = Constants.landuseColor
        }
        fill.fillColor = NSExpression(forConstantValue: color)
        fill.fillOutlineColor = NSExpression(forConstantValue: color)
    }

    static func darken(_ line: MLNLineStyleLayer) {
        let color: UIColor
        switch line.sourceLayerIdentifier {
        case "waterway":
            color = .mapDarkWater
        case "park":
            color = .mapDarkVegetation
        case "boundary":
            color = Constants.boundaryColor
        case "transportation", "aeroway":
            color = line.identifier.contains("casing") ? Constants.roadCasingColor : roadColor(of: line)
        default:
            return
        }
        line.lineColor = NSExpression(forConstantValue: color)
    }

    /// Motorways and main roads a step lighter than the streets, as in the light style.
    static func roadColor(of line: MLNLineStyleLayer) -> UIColor {
        let isMajor = ["motorway", "trunk", "primary"].contains { line.identifier.contains($0) }
        return isMajor ? Constants.majorRoadColor : Constants.roadColor
    }

    /// Names other than places (water, roads, points of interest): light text on a dark halo. Place names take the
    /// map's palette in ``BaseMapRestyler``.
    static func darken(_ label: MLNSymbolStyleLayer) {
        // Road shields keep their dark numbers on the white plate.
        guard label.sourceLayerIdentifier != "place",
              String(describing: label.text.mgl_jsonExpressionObject).contains(Constants.nameKey) else { return }
        label.textColor = NSExpression(forConstantValue: Constants.secondaryLabelColor)
        label.textHaloColor = NSExpression(forConstantValue: UIColor.mapHalo)
    }
}

// MARK: - Constants

private enum Constants {
    static let reliefBrightness: Double = 0.25
    static let landuseColor = UIColor(white: 0.14, alpha: 1)
    static let bareLandColor = UIColor(white: 0.18, alpha: 1)
    static let boundaryColor = UIColor(white: 0.55, alpha: 1)
    static let roadColor = UIColor(white: 0.3, alpha: 1)
    static let majorRoadColor = UIColor(white: 0.42, alpha: 1)
    static let roadCasingColor = UIColor(white: 0.08, alpha: 1)
    static let secondaryLabelColor = UIColor(white: 0.72, alpha: 1)
    static let nameKey = "name"
}
