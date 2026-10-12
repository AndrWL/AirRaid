//
//  MapFeatureFactory.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import MapLibre

/// Turns domain geometry into MapLibre features and styles the alert fills, for ``AirRaidMapView``.
enum MapFeatureFactory {

    /// A fill colored by the official level.
    static func makeAlertFill(
        identifier: String,
        source: MLNShapeSource,
        opacity: NSExpression
    ) -> MLNFillStyleLayer {
        let fill = MLNFillStyleLayer(identifier: identifier, source: source)
        fill.predicate = NSPredicate(format: "%K != %@", MapLayerStyle.alertLevelKey, MapLayerStyle.noAlert)
        fill.fillColor = NSExpression(
            forMLNMatchingKey: NSExpression(forKeyPath: MapLayerStyle.alertLevelKey),
            in: [NSExpression(forConstantValue: MapLayerStyle.yellowLevel): NSExpression(forConstantValue: MapLayerStyle.yellowAlertColor)],
            default: NSExpression(forConstantValue: MapLayerStyle.redAlertColor)
        )
        fill.fillOpacity = opacity
        return fill
    }

    /// A plain line along a source's polygons; round joins keep the bright outlines from spiking at sharp corners.
    static func makeOutline(
        identifier: String,
        source: MLNShapeSource,
        color: UIColor,
        opacity: Double,
        width: Double
    ) -> MLNLineStyleLayer {
        let outline = MLNLineStyleLayer(identifier: identifier, source: source)
        outline.lineColor = NSExpression(forConstantValue: color)
        outline.lineOpacity = NSExpression(forConstantValue: opacity)
        outline.lineWidth = NSExpression(forConstantValue: width)
        outline.lineJoin = NSExpression(forConstantValue: MapLayerStyle.roundJoin)
        return outline
    }

    /// A pin where there is no alert is probably misplaced (a namesake in another oblast): faded, not hidden.
    /// A pin outside the focused region fades further: it is context, not what the user is watching.
    static func makePinOpacity() -> NSExpression {
        NSExpression(
            forMLNConditional: NSPredicate(format: "%K == YES", MapLayerStyle.outsideFocusKey),
            trueExpression: NSExpression(forConstantValue: MapLayerStyle.outsideFocusOpacity),
            falseExpression: NSExpression(
                forMLNConditional: NSPredicate(format: "%K == YES", MapLayerStyle.outsideAlertKey),
                trueExpression: NSExpression(forConstantValue: MapLayerStyle.outsideAlertOpacity),
                falseExpression: NSExpression(forConstantValue: 1)
            )
        )
    }

    static func makeDistrictFeatures(from districts: [DistrictBoundary]) -> [DistrictKey: MLNMultiPolygonFeature] {
        Dictionary(
            districts.map { district in
                let feature = MLNMultiPolygonFeature(polygons: district.polygons.map(makePolygon))
                feature.identifier = district.id
                return (district.key, feature)
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    static func value(of level: RegionAlertLevel) -> String {
        switch level {
        case .yellow: return MapLayerStyle.yellowLevel
        case .red: return MapLayerStyle.redLevel
        }
    }

    static func value(of extent: RegionAlertExtent) -> String {
        switch extent {
        case .partial: return MapLayerStyle.partialExtent
        case .whole: return MapLayerStyle.wholeExtent
        }
    }

    static func makeRegionFeatures(from boundaries: [RegionBoundary]) -> [String: MLNMultiPolygonFeature] {
        Dictionary(uniqueKeysWithValues: boundaries.map { boundary in
            let feature = MLNMultiPolygonFeature(polygons: boundary.polygons.map(makePolygon))
            feature.identifier = boundary.id
            // An attribute too: filters and tap queries read attributes, not identifiers, reliably.
            feature.attributes[MapLayerStyle.regionIDKey] = boundary.id
            return (boundary.id, feature)
        })
    }

    static func makePolygon(from polygon: GeoPolygon) -> MLNPolygon {
        let holes = polygon.holes.map { ring in
            var coordinates = ring.map(CLLocationCoordinate2D.init)
            return MLNPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
        }
        var exterior = polygon.exterior.map(CLLocationCoordinate2D.init)
        return MLNPolygon(coordinates: &exterior, count: UInt(exterior.count), interiorPolygons: holes)
    }
}

// MARK: - CLLocationCoordinate2D

extension CLLocationCoordinate2D {

    init(_ coordinate: GeoCoordinate) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

// MARK: - GeoCoordinate

extension GeoCoordinate {

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
