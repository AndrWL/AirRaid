//
//  AirRaidMapView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import MapLibre
import SwiftUI

/// A MapLibre map of Ukraine with alerted regions filled, regional centers labelled, and threats shown as pins.
///
/// Regions, cities, and threats are style layers over GeoJSON sources rather than annotations: the GPU draws
/// them, and an update replaces one source instead of diffing views.
/// - Note: MapLibre is imported only in this folder; everything outside works with domain models.
struct AirRaidMapView: UIViewRepresentable {

    // MARK: - Variables

    let styleURL: URL
    let boundaries: [RegionBoundary]
    let cities: [City]
    let alertedRegionIDs: Set<String>
    let threats: [Threat]

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        context.coordinator.update(
            boundaries: boundaries,
            cities: cities,
            alertedRegionIDs: alertedRegionIDs,
            threats: threats
        )
    }
}

// MARK: - Coordinator

extension AirRaidMapView {

    /// Owns the map's sources and keeps them in sync with the latest data.
    ///
    /// Data can arrive before the style finishes loading, so the latest values are kept and applied
    /// once the style is ready.
    final class Coordinator: NSObject {

        // MARK: - Variables

        private var regionSource: MLNShapeSource?
        private var citySource: MLNShapeSource?
        private var threatSource: MLNShapeSource?

        /// The base style's city label layers with their original filters, extended once cities are known.
        private var baseCityLabels: [(layer: MLNSymbolStyleLayer, predicate: NSPredicate?)] = []

        private var boundaries: [RegionBoundary] = []
        private var cities: [City] = []
        private var alertedRegionIDs: Set<String> = []
        private var threats: [Threat] = []

        /// Region features by region ID, rebuilt only when the outlines change.
        private var regionFeatures: [String: MLNMultiPolygonFeature] = [:]

        func update(
            boundaries: [RegionBoundary],
            cities: [City],
            alertedRegionIDs: Set<String>,
            threats: [Threat]
        ) {
            let boundariesChanged = boundaries.map(\.id) != self.boundaries.map(\.id)
            let citiesChanged = cities != self.cities
            let alertsChanged = alertedRegionIDs != self.alertedRegionIDs
            let threatsChanged = threats != self.threats

            self.boundaries = boundaries
            self.cities = cities
            self.alertedRegionIDs = alertedRegionIDs
            self.threats = threats

            if boundariesChanged {
                regionFeatures = Self.makeRegionFeatures(from: boundaries)
            }
            if boundariesChanged || alertsChanged {
                applyRegions()
            }
            if citiesChanged {
                applyCities()
            }
            if threatsChanged {
                applyThreats()
            }
        }
    }
}

// MARK: - MLNMapViewDelegate

extension AirRaidMapView.Coordinator: MLNMapViewDelegate {

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        // Here rather than in `makeUIView`: the view has its real size only by now, and fitting needs it.
        mapView.setVisibleCoordinateBounds(
            Constants.ukraineBounds,
            edgePadding: Constants.ukraineEdgePadding,
            animated: false,
            completionHandler: nil
        )
        installLayers(in: style)
        applyRegions()
        applyCities()
        applyThreats()
    }
}

// MARK: - Private methods

private extension AirRaidMapView.Coordinator {

    func installLayers(in style: MLNStyle) {
        let regionSource = MLNShapeSource(identifier: Constants.regionSourceID, shape: nil)
        let citySource = MLNShapeSource(identifier: Constants.citySourceID, shape: nil)
        let threatSource = MLNShapeSource(identifier: Constants.threatSourceID, shape: nil)
        [regionSource, citySource, threatSource].forEach(style.addSource)
        self.regionSource = regionSource
        self.citySource = citySource
        self.threatSource = threatSource

        BaseMapRestyler.restyle(style)
        baseCityLabels = BaseMapRestyler.cityLabelLayers(in: style).map { ($0, $0.predicate) }

        installRegionLayers(in: style, source: regionSource)
        installCityLayer(in: style, source: citySource)
        installThreatLayer(in: style, source: threatSource)
    }

    func installRegionLayers(in style: MLNStyle, source: MLNShapeSource) {
        // Tints the whole country, so Ukraine stands out from the dark base map.
        let territoryFill = MLNFillStyleLayer(identifier: Constants.territoryFillLayerID, source: source)
        territoryFill.fillColor = NSExpression(forConstantValue: Constants.territoryColor)
        territoryFill.fillOpacity = NSExpression(forConstantValue: Constants.territoryFillOpacity)

        let alertFill = MLNFillStyleLayer(identifier: Constants.alertFillLayerID, source: source)
        alertFill.predicate = NSPredicate(format: "%K == YES", Constants.isAlertedKey)
        alertFill.fillColor = NSExpression(forConstantValue: Constants.alertColor)
        alertFill.fillOpacity = NSExpression(forConstantValue: Constants.alertFillOpacity)

        let outline = MLNLineStyleLayer(identifier: Constants.outlineLayerID, source: source)
        outline.lineColor = NSExpression(forConstantValue: UIColor.white)
        outline.lineOpacity = NSExpression(forConstantValue: Constants.outlineOpacity)
        outline.lineWidth = NSExpression(forConstantValue: Constants.outlineWidth)

        // Below the first label layer, so the base map's names stay readable over the fill.
        let regionLayers = [territoryFill, alertFill, outline]
        if let firstLabelLayer = style.layers.first(where: { $0 is MLNSymbolStyleLayer }) {
            regionLayers.forEach { style.insertLayer($0, below: firstLabelLayer) }
        } else {
            regionLayers.forEach(style.addLayer)
        }
    }

    func installCityLayer(in style: MLNStyle, source: MLNShapeSource) {
        let cityLabels = MLNSymbolStyleLayer(identifier: Constants.cityLayerID, source: source)
        cityLabels.text = NSExpression(forKeyPath: Constants.nameKey)
        cityLabels.textFontNames = NSExpression(forConstantValue: Constants.cityFontNames)
        cityLabels.textFontSize = NSExpression(forConstantValue: Constants.cityFontSize)
        cityLabels.textColor = NSExpression(forConstantValue: UIColor.white)
        cityLabels.textHaloColor = NSExpression(forConstantValue: UIColor.black.withAlphaComponent(Constants.cityHaloAlpha))
        cityLabels.textHaloWidth = NSExpression(forConstantValue: Constants.cityHaloWidth)
        style.addLayer(cityLabels)
    }

    func installThreatLayer(in style: MLNStyle, source: MLNShapeSource) {
        for icon in ThreatIcon.allCases {
            style.setImage(icon.image, forName: icon.name)
        }
        let threatPins = MLNSymbolStyleLayer(identifier: Constants.threatLayerID, source: source)
        threatPins.iconImageName = NSExpression(forKeyPath: Constants.iconNameKey)
        threatPins.iconRotation = NSExpression(forKeyPath: Constants.headingKey)
        threatPins.iconRotationAlignment = NSExpression(forConstantValue: Constants.mapAlignment)
        threatPins.iconScale = NSExpression(forConstantValue: Constants.threatIconScale)
        threatPins.iconAllowsOverlap = NSExpression(forConstantValue: true)
        threatPins.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        style.addLayer(threatPins)
    }

    func applyRegions() {
        guard let regionSource else { return }
        for (regionID, feature) in regionFeatures {
            feature.attributes[Constants.isAlertedKey] = alertedRegionIDs.contains(regionID)
        }
        regionSource.shape = MLNShapeCollectionFeature(shapes: Array(regionFeatures.values))
    }

    func applyCities() {
        guard let citySource else { return }
        citySource.shape = MLNShapeCollectionFeature(shapes: cities.map { city in
            let feature = MLNPointFeature()
            feature.coordinate = CLLocationCoordinate2D(city.coordinate)
            feature.attributes = [Constants.nameKey: city.name]
            return feature
        })

        // The base map labels some of the same cities (Kyiv); drop those so each name appears once.
        let names = cities.map(\.name)
        let notOurCity = NSPredicate(format: "NOT (%K IN %@)", BaseMapRestyler.localNameKey, names)
        for (layer, originalPredicate) in baseCityLabels {
            layer.predicate = originalPredicate.map { NSCompoundPredicate(andPredicateWithSubpredicates: [$0, notOurCity]) }
                ?? notOurCity
        }
    }

    func applyThreats() {
        guard let threatSource else { return }
        threatSource.shape = MLNShapeCollectionFeature(shapes: threats.map { threat in
            let feature = MLNPointFeature()
            feature.coordinate = CLLocationCoordinate2D(threat.coordinate)
            feature.identifier = threat.id
            let icon = ThreatIcon(threat)
            feature.attributes = [
                Constants.iconNameKey: icon.name,
                // Unknown heading draws the icon pointing north.
                Constants.headingKey: icon.rotatesWithHeading ? threat.heading ?? 0 : 0
            ]
            return feature
        })
    }

    static func makeRegionFeatures(from boundaries: [RegionBoundary]) -> [String: MLNMultiPolygonFeature] {
        Dictionary(uniqueKeysWithValues: boundaries.map { boundary in
            let feature = MLNMultiPolygonFeature(polygons: boundary.polygons.map(makePolygon))
            feature.identifier = boundary.id
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

private extension CLLocationCoordinate2D {

    init(_ coordinate: GeoCoordinate) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

// MARK: - Constants

private enum Constants {
    /// Ukraine's bounding box; the camera fits it on load so the whole country is visible on any screen.
    static let ukraineBounds = MLNCoordinateBounds(
        sw: CLLocationCoordinate2D(latitude: 44.3, longitude: 22.1),
        ne: CLLocationCoordinate2D(latitude: 52.4, longitude: 40.3)
    )
    static let ukraineEdgePadding = UIEdgeInsets(top: 60, left: 8, bottom: 8, right: 8)

    static let regionSourceID = "regions"
    static let citySourceID = "cities"
    static let threatSourceID = "threats"
    static let territoryFillLayerID = "regions-territory-fill"
    static let alertFillLayerID = "regions-alert-fill"
    static let outlineLayerID = "regions-outline"
    static let cityLayerID = "cities-labels"
    static let threatLayerID = "threats-pins"

    static let isAlertedKey = "isAlerted"
    static let nameKey = "name"
    static let iconNameKey = "iconName"
    static let headingKey = "heading"
    static let mapAlignment = "map"

    static let territoryColor = UIColor(red: 0.29, green: 0.31, blue: 0.20, alpha: 1)
    static let territoryFillOpacity: Double = 0.55
    static let alertColor = UIColor(red: 0.72, green: 0.34, blue: 0.28, alpha: 1)
    static let alertFillOpacity: Double = 0.7
    static let outlineOpacity: Double = 0.35
    static let outlineWidth: Double = 0.8

    /// A font the OpenFreeMap glyph server provides.
    static let cityFontNames = ["Noto Sans Bold"]
    static let cityFontSize: Double = 11
    static let threatIconScale: Double = 0.75
    static let cityHaloAlpha: CGFloat = 0.8
    static let cityHaloWidth: Double = 1.2
}

#Preview {
    if let styleURL = URL(string: AppEnvironment.mapStyleURLString) {
        AirRaidMapView(
            styleURL: styleURL,
            boundaries: [],
            cities: [],
            alertedRegionIDs: [],
            threats: []
        )
    }
}
