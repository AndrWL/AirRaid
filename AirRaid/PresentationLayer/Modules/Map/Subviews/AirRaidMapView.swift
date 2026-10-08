//
//  AirRaidMapView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import MapLibre
import SwiftUI

/// A MapLibre map of Ukraine with air raid alerts filled by oblast or raion (color by alert level),
/// regional centers labelled, and threats shown as pins.
///
/// Regions, cities, and threats are style layers over GeoJSON sources rather than annotations: the GPU draws
/// them, and an update replaces one source instead of diffing views.
/// - Note: MapLibre is imported only in this folder; everything outside works with domain models.
struct AirRaidMapView: UIViewRepresentable {

    // MARK: - Variables

    let styleURL: URL
    let boundaries: [RegionBoundary]
    let districts: [DistrictBoundary]
    let cities: [City]
    let alertCoverage: AirRaidCoverage
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
            districts: districts,
            cities: cities,
            alertCoverage: alertCoverage,
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
        private var districtSource: MLNShapeSource?
        private var citySource: MLNShapeSource?
        private var threatSource: MLNShapeSource?

        /// The base style's city label layers with their original filters, extended once cities are known.
        private var baseCityLabels: [(layer: MLNSymbolStyleLayer, predicate: NSPredicate?)] = []

        private var boundaries: [RegionBoundary] = []
        private var districts: [DistrictBoundary] = []
        private var cities: [City] = []
        private var alertCoverage: AirRaidCoverage = .none
        private var threats: [Threat] = []

        /// Region features by region ID, rebuilt only when the outlines change.
        private var regionFeatures: [String: MLNMultiPolygonFeature] = [:]

        /// Raion features by how alerts name them, rebuilt only when the outlines change.
        private var districtFeatures: [DistrictKey: MLNMultiPolygonFeature] = [:]

        func update(
            boundaries: [RegionBoundary],
            districts: [DistrictBoundary],
            cities: [City],
            alertCoverage: AirRaidCoverage,
            threats: [Threat]
        ) {
            let boundariesChanged = boundaries.map(\.id) != self.boundaries.map(\.id)
            let districtsChanged = districts.map(\.id) != self.districts.map(\.id)
            let citiesChanged = cities != self.cities
            let alertsChanged = alertCoverage != self.alertCoverage
            let threatsChanged = threats != self.threats

            self.boundaries = boundaries
            self.districts = districts
            self.cities = cities
            self.alertCoverage = alertCoverage
            self.threats = threats

            if boundariesChanged {
                regionFeatures = Self.makeRegionFeatures(from: boundaries)
            }
            if boundariesChanged || alertsChanged {
                applyRegions()
            }
            if districtsChanged {
                districtFeatures = Self.makeDistrictFeatures(from: districts)
            }
            if districtsChanged || alertsChanged {
                applyDistricts()
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
        applyDistricts()
        applyCities()
        applyThreats()
    }
}

// MARK: - Private methods

private extension AirRaidMapView.Coordinator {

    func installLayers(in style: MLNStyle) {
        let regionSource = MLNShapeSource(identifier: Constants.regionSourceID, shape: nil)
        let districtSource = MLNShapeSource(identifier: Constants.districtSourceID, shape: nil)
        let citySource = MLNShapeSource(identifier: Constants.citySourceID, shape: nil)
        let threatSource = MLNShapeSource(identifier: Constants.threatSourceID, shape: nil)
        [regionSource, districtSource, citySource, threatSource].forEach(style.addSource)
        self.regionSource = regionSource
        self.districtSource = districtSource
        self.citySource = citySource
        self.threatSource = threatSource

        BaseMapRestyler.restyle(style)
        baseCityLabels = BaseMapRestyler.cityLabelLayers(in: style).map { ($0, $0.predicate) }

        installRegionLayers(in: style, regionSource: regionSource, districtSource: districtSource)
        installCityLayer(in: style, source: citySource)
        installThreatLayer(in: style, source: threatSource)
    }

    func installRegionLayers(
        in style: MLNStyle,
        regionSource: MLNShapeSource,
        districtSource: MLNShapeSource
    ) {
        // Tints the whole country, so Ukraine stands out from the dark base map.
        let territoryFill = MLNFillStyleLayer(identifier: Constants.territoryFillLayerID, source: regionSource)
        territoryFill.fillColor = NSExpression(forConstantValue: Constants.territoryColor)
        territoryFill.fillOpacity = NSExpression(forConstantValue: Constants.territoryFillOpacity)

        let regionAlertFill = Self.makeAlertFill(
            identifier: Constants.regionAlertFillLayerID,
            source: regionSource,
            opacity: NSExpression(forConstantValue: Constants.wholeAlertFillOpacity)
        )
        // A raion alert is filled as strongly as an oblast one; a hromada inside the raion only faintly.
        let districtAlertFill = Self.makeAlertFill(
            identifier: Constants.districtAlertFillLayerID,
            source: districtSource,
            opacity: NSExpression(
                forMLNMatchingKey: NSExpression(forKeyPath: Constants.alertExtentKey),
                in: [
                    NSExpression(forConstantValue: Constants.wholeExtent): NSExpression(forConstantValue: Constants.wholeAlertFillOpacity)
                ],
                default: NSExpression(forConstantValue: Constants.partialAlertFillOpacity)
            )
        )

        // Raion borders only inside alerted raions, so the alerted part reads as such without cluttering the map.
        let districtOutline = MLNLineStyleLayer(identifier: Constants.districtOutlineLayerID, source: districtSource)
        districtOutline.lineColor = NSExpression(forConstantValue: UIColor.white)
        districtOutline.lineOpacity = NSExpression(forConstantValue: Constants.districtOutlineOpacity)
        districtOutline.lineWidth = NSExpression(forConstantValue: Constants.districtOutlineWidth)

        let outline = MLNLineStyleLayer(identifier: Constants.outlineLayerID, source: regionSource)
        outline.lineColor = NSExpression(forConstantValue: UIColor.white)
        outline.lineOpacity = NSExpression(forConstantValue: Constants.outlineOpacity)
        outline.lineWidth = NSExpression(forConstantValue: Constants.outlineWidth)

        // Below the first label layer, so the base map's names stay readable over the fill.
        let regionLayers = [territoryFill, regionAlertFill, districtAlertFill, districtOutline, outline]
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
            let level = alertCoverage.regions[regionID]
            feature.attributes[Constants.alertLevelKey] = level.map(Self.value) ?? Constants.noAlert
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
        // Country-wide reports have no place on the map.
        threatSource.shape = MLNShapeCollectionFeature(shapes: threats.compactMap { threat -> MLNPointFeature? in
            guard let coordinate = threat.markerCoordinate else { return nil }
            let feature = MLNPointFeature()
            feature.coordinate = CLLocationCoordinate2D(coordinate)
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

    /// Only alerted raions go into the source: drawing all 137 just to hide them would cost for nothing.
    func applyDistricts() {
        guard let districtSource else { return }
        let alerted = alertCoverage.districts.compactMap { key, coverage -> MLNMultiPolygonFeature? in
            guard let feature = districtFeatures[key] else { return nil }
            feature.attributes[Constants.alertLevelKey] = Self.value(of: coverage.level)
            feature.attributes[Constants.alertExtentKey] = Self.value(of: coverage.extent)
            return feature
        }
        districtSource.shape = MLNShapeCollectionFeature(shapes: alerted)
    }

    /// A fill colored by the official level.
    static func makeAlertFill(
        identifier: String,
        source: MLNShapeSource,
        opacity: NSExpression
    ) -> MLNFillStyleLayer {
        let fill = MLNFillStyleLayer(identifier: identifier, source: source)
        fill.predicate = NSPredicate(format: "%K != %@", Constants.alertLevelKey, Constants.noAlert)
        fill.fillColor = NSExpression(
            forMLNMatchingKey: NSExpression(forKeyPath: Constants.alertLevelKey),
            in: [NSExpression(forConstantValue: Constants.yellowLevel): NSExpression(forConstantValue: Constants.yellowAlertColor)],
            default: NSExpression(forConstantValue: Constants.redAlertColor)
        )
        fill.fillOpacity = opacity
        return fill
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
        case .yellow: return Constants.yellowLevel
        case .red: return Constants.redLevel
        }
    }

    static func value(of extent: RegionAlertExtent) -> String {
        switch extent {
        case .partial: return Constants.partialExtent
        case .whole: return Constants.wholeExtent
        }
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
    static let districtSourceID = "districts"
    static let citySourceID = "cities"
    static let threatSourceID = "threats"
    static let territoryFillLayerID = "regions-territory-fill"
    static let regionAlertFillLayerID = "regions-alert-fill"
    static let districtAlertFillLayerID = "districts-alert-fill"
    static let districtOutlineLayerID = "districts-outline"
    static let outlineLayerID = "regions-outline"
    static let cityLayerID = "cities-labels"
    static let threatLayerID = "threats-pins"

    static let alertLevelKey = "alertLevel"
    static let alertExtentKey = "alertExtent"
    static let noAlert = "none"
    static let yellowLevel = "yellow"
    static let redLevel = "red"
    static let partialExtent = "partial"
    static let wholeExtent = "whole"
    static let nameKey = "name"
    static let iconNameKey = "iconName"
    static let headingKey = "heading"
    static let mapAlignment = "map"

    static let territoryColor = UIColor(red: 0.29, green: 0.31, blue: 0.20, alpha: 1)
    static let territoryFillOpacity: Double = 0.55
    static let redAlertColor = UIColor(red: 0.72, green: 0.34, blue: 0.28, alpha: 1)
    static let yellowAlertColor = UIColor(red: 0.80, green: 0.66, blue: 0.24, alpha: 1)
    static let wholeAlertFillOpacity: Double = 0.7
    static let partialAlertFillOpacity: Double = 0.35
    static let outlineOpacity: Double = 0.35
    static let outlineWidth: Double = 0.8
    static let districtOutlineOpacity: Double = 0.2
    static let districtOutlineWidth: Double = 0.5

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
            districts: [],
            cities: [],
            alertCoverage: .none,
            threats: []
        )
    }
}
