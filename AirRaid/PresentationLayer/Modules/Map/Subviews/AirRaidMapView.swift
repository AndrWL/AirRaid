//
//  AirRaidMapView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import MapLibre
import SwiftUI

/// A MapLibre map of Ukraine with air raid alerts filled by oblast or raion (color by alert level),
/// regional centers labelled, and threats shown as pins. Tapping a pin selects it; the selected threat is drawn
/// larger, with its track behind it and a dashed line to its target. A tap that hits no pin selects the region under
/// it, which gets a bright outline.
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
    let selection: MapSelection?

    /// Called with the tapped pin, else the tapped region, or `nil` when a tap hits neither.
    let onSelect: (MapSelection?) -> Void

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.allowsRotating = false
        mapView.allowsTilting = false

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.delegate = context.coordinator
        // Let the map's own double tap (zoom in) win, so a zoom is not also read as a selection.
        for recognizer in mapView.gestureRecognizers ?? [] {
            if let doubleTap = recognizer as? UITapGestureRecognizer, doubleTap.numberOfTapsRequired == 2 {
                tap.require(toFail: doubleTap)
            }
        }
        mapView.addGestureRecognizer(tap)
        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        context.coordinator.onSelect = onSelect
        context.coordinator.update(
            boundaries: boundaries,
            districts: districts,
            cities: cities,
            alertCoverage: alertCoverage,
            threats: threats,
            selection: selection
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
        private var selectedTrackSource: MLNShapeSource?

        var onSelect: (MapSelection?) -> Void = { _ in }

        /// The base style's city label layers with their original filters, extended once cities are known.
        private var baseCityLabels: [(layer: MLNSymbolStyleLayer, predicate: NSPredicate?)] = []

        private var boundaries: [RegionBoundary] = []
        private var districts: [DistrictBoundary] = []
        private var cities: [City] = []
        private var alertCoverage: AirRaidCoverage = .none
        private var threats: [Threat] = []
        private var selection: MapSelection?

        /// The selected-region outline, whose filter follows the selection.
        private var selectedRegionOutline: MLNLineStyleLayer?

        /// Region features by region ID, rebuilt only when the outlines change.
        private var regionFeatures: [String: MLNMultiPolygonFeature] = [:]

        /// Raion features by how alerts name them, rebuilt only when the outlines change.
        private var districtFeatures: [DistrictKey: MLNMultiPolygonFeature] = [:]

        func update(
            boundaries: [RegionBoundary],
            districts: [DistrictBoundary],
            cities: [City],
            alertCoverage: AirRaidCoverage,
            threats: [Threat],
            selection: MapSelection?
        ) {
            let boundariesChanged = boundaries.map(\.id) != self.boundaries.map(\.id)
            let districtsChanged = districts.map(\.id) != self.districts.map(\.id)
            let citiesChanged = cities != self.cities
            let alertsChanged = alertCoverage != self.alertCoverage
            let threatsChanged = threats != self.threats
            let selectionChanged = selection != self.selection

            self.boundaries = boundaries
            self.districts = districts
            self.cities = cities
            self.alertCoverage = alertCoverage
            self.threats = threats
            self.selection = selection

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
            if selectionChanged {
                applySelectedRegion()
            }
            // An area-only threat is placed by the alerts, so its pin moves when they change.
            if threatsChanged || selectionChanged || alertsChanged || districtsChanged {
                applyThreats()
                applySelectedTrack()
            }
        }

        /// Selects the pin nearest to the tap, else the region under it, or clears the selection when the tap hits
        /// neither — outside Ukraine.
        @objc
        func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, let mapView = recognizer.view as? MLNMapView else { return }
            let point = recognizer.location(in: mapView)
            let hitArea = CGRect(
                x: point.x - Constants.tapRadius,
                y: point.y - Constants.tapRadius,
                width: Constants.tapRadius * 2,
                height: Constants.tapRadius * 2
            )
            let nearest = mapView.visibleFeatures(in: hitArea, styleLayerIdentifiers: [Constants.threatLayerID])
                .min { lhs, rhs in
                    Self.distance(from: point, to: lhs, in: mapView) < Self.distance(from: point, to: rhs, in: mapView)
                }
            if let threatID = nearest?.identifier as? String {
                onSelect(.threat(id: threatID))
                return
            }
            let region = mapView.visibleFeatures(at: point, styleLayerIdentifiers: [Constants.territoryFillLayerID]).first
            onSelect((region?.attributes[Constants.regionIDKey] as? String).map { .region(id: $0) })
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
        applySelectedRegion()
        applyThreats()
        applySelectedTrack()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension AirRaidMapView.Coordinator: UIGestureRecognizerDelegate {

    /// The map has its own single tap (for annotations) that would otherwise swallow ours.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - Private methods

private extension AirRaidMapView.Coordinator {

    func installLayers(in style: MLNStyle) {
        let regionSource = MLNShapeSource(identifier: Constants.regionSourceID, shape: nil)
        let districtSource = MLNShapeSource(identifier: Constants.districtSourceID, shape: nil)
        let citySource = MLNShapeSource(identifier: Constants.citySourceID, shape: nil)
        let threatSource = MLNShapeSource(identifier: Constants.threatSourceID, shape: nil)
        let selectedTrackSource = MLNShapeSource(identifier: Constants.selectedTrackSourceID, shape: nil)
        [regionSource, districtSource, citySource, threatSource, selectedTrackSource].forEach(style.addSource)
        self.regionSource = regionSource
        self.districtSource = districtSource
        self.citySource = citySource
        self.threatSource = threatSource
        self.selectedTrackSource = selectedTrackSource

        BaseMapRestyler.restyle(style)
        baseCityLabels = BaseMapRestyler.cityLabelLayers(in: style).map { ($0, $0.predicate) }

        installRegionLayers(in: style, regionSource: regionSource, districtSource: districtSource)
        installCityLayer(in: style, source: citySource)
        installSelectedTrackLayers(in: style, source: selectedTrackSource)
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
        districtOutline.lineColor = NSExpression(forConstantValue: UIColor.mapOutline)
        districtOutline.lineOpacity = NSExpression(forConstantValue: Constants.districtOutlineOpacity)
        districtOutline.lineWidth = NSExpression(forConstantValue: Constants.districtOutlineWidth)

        let outline = MLNLineStyleLayer(identifier: Constants.outlineLayerID, source: regionSource)
        outline.lineColor = NSExpression(forConstantValue: UIColor.mapOutline)
        outline.lineOpacity = NSExpression(forConstantValue: Constants.outlineOpacity)
        outline.lineWidth = NSExpression(forConstantValue: Constants.outlineWidth)

        let selectedOutline = MLNLineStyleLayer(identifier: Constants.selectedRegionOutlineLayerID, source: regionSource)
        selectedOutline.lineColor = NSExpression(forConstantValue: Constants.selectedRegionColor)
        selectedOutline.lineOpacity = NSExpression(forConstantValue: Constants.selectedRegionOutlineOpacity)
        selectedOutline.lineWidth = NSExpression(forConstantValue: Constants.selectedRegionOutlineWidth)
        selectedOutline.lineJoin = NSExpression(forConstantValue: Constants.roundJoin)
        selectedRegionOutline = selectedOutline

        // Below the first label layer, so the base map's names stay readable over the fill.
        let regionLayers = [territoryFill, regionAlertFill, districtAlertFill, districtOutline, outline, selectedOutline]
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
        cityLabels.textColor = NSExpression(forConstantValue: UIColor.mapLabel)
        cityLabels.textHaloColor = NSExpression(forConstantValue: UIColor.mapHalo)
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
        threatPins.iconScale = NSExpression(
            forMLNConditional: NSPredicate(format: "%K == YES", Constants.selectedKey),
            trueExpression: NSExpression(forConstantValue: Constants.selectedThreatIconScale),
            falseExpression: NSExpression(forConstantValue: Constants.threatIconScale)
        )
        threatPins.iconAllowsOverlap = NSExpression(forConstantValue: true)
        threatPins.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        // A pin where there is no alert is probably misplaced (a namesake in another oblast): faded, not hidden.
        let outsideAlertOpacity = NSExpression(
            forMLNConditional: NSPredicate(format: "%K == YES", Constants.outsideAlertKey),
            trueExpression: NSExpression(forConstantValue: Constants.outsideAlertOpacity),
            falseExpression: NSExpression(forConstantValue: 1)
        )
        threatPins.iconOpacity = outsideAlertOpacity
        threatPins.textOpacity = outsideAlertOpacity

        // The caption under the pin; captions that would collide are hidden, the pins always stay.
        let captionLabel = MLNAttributedExpression(
            NSExpression(forKeyPath: Constants.captionLabelKey),
            attributes: [
                .fontNamesAttribute: NSExpression(forConstantValue: Constants.captionLabelFontNames),
                .fontScaleAttribute: NSExpression(forConstantValue: Constants.captionLabelScale),
                .fontColorAttribute: NSExpression(forConstantValue: Constants.captionLabelColor)
            ]
        )
        let captionName = MLNAttributedExpression(NSExpression(forKeyPath: Constants.captionNameKey))
        threatPins.text = NSExpression(forAttributedExpressions: [captionLabel, captionName].map {
            NSExpression(forConstantValue: $0)
        })
        threatPins.textFontNames = NSExpression(forConstantValue: Constants.cityFontNames)
        threatPins.textFontSize = NSExpression(forConstantValue: Constants.threatCaptionFontSize)
        threatPins.textColor = NSExpression(forConstantValue: UIColor.mapLabel)
        threatPins.textHaloColor = NSExpression(forConstantValue: UIColor.mapHalo)
        threatPins.textHaloWidth = NSExpression(forConstantValue: Constants.cityHaloWidth)
        threatPins.textAnchor = NSExpression(forConstantValue: Constants.topAnchor)
        threatPins.textOffset = NSExpression(
            forMLNConditional: NSPredicate(format: "%K == YES", Constants.selectedKey),
            trueExpression: NSExpression(forConstantValue: NSValue(cgVector: Constants.selectedThreatCaptionOffset)),
            falseExpression: NSExpression(forConstantValue: NSValue(cgVector: Constants.threatCaptionOffset))
        )
        threatPins.textOptional = NSExpression(forConstantValue: true)
        threatPins.textAllowsOverlap = NSExpression(forConstantValue: false)
        style.addLayer(threatPins)
    }

    /// The selected threat's path: where it has been (solid) and where it is heading (dashed).
    func installSelectedTrackLayers(in style: MLNStyle, source: MLNShapeSource) {
        let trail = MLNLineStyleLayer(identifier: Constants.selectedTrailLayerID, source: source)
        trail.predicate = NSPredicate(format: "%K == %@", Constants.trackPartKey, Constants.trailPart)
        trail.lineColor = NSExpression(forConstantValue: Constants.trackColor)
        trail.lineOpacity = NSExpression(forConstantValue: Constants.trailOpacity)
        trail.lineWidth = NSExpression(forConstantValue: Constants.trackWidth)
        trail.lineJoin = NSExpression(forConstantValue: Constants.roundJoin)

        let forecast = MLNLineStyleLayer(identifier: Constants.selectedForecastLayerID, source: source)
        forecast.predicate = NSPredicate(format: "%K == %@", Constants.trackPartKey, Constants.forecastPart)
        forecast.lineColor = NSExpression(forConstantValue: Constants.trackColor)
        forecast.lineOpacity = NSExpression(forConstantValue: Constants.forecastOpacity)
        forecast.lineWidth = NSExpression(forConstantValue: Constants.trackWidth)
        forecast.lineDashPattern = NSExpression(forConstantValue: Constants.forecastDashPattern)

        let targetDot = MLNCircleStyleLayer(identifier: Constants.selectedTargetLayerID, source: source)
        targetDot.predicate = NSPredicate(format: "%K == %@", Constants.trackPartKey, Constants.targetPart)
        targetDot.circleRadius = NSExpression(forConstantValue: Constants.targetDotRadius)
        targetDot.circleColor = NSExpression(forConstantValue: UIColor.clear)
        targetDot.circleStrokeColor = NSExpression(forConstantValue: Constants.trackColor)
        targetDot.circleStrokeWidth = NSExpression(forConstantValue: Constants.trackWidth)
        targetDot.circleStrokeOpacity = NSExpression(forConstantValue: Constants.forecastOpacity)

        [trail, forecast, targetDot].forEach(style.addLayer)
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
            guard let coordinate = threat.markerCoordinate(coverage: alertCoverage, districts: districts) else { return nil }
            // Until the outlines load nothing can be checked, so nothing is faded.
            let isOutsideAlert = !boundaries.isEmpty
                && !alertCoverage.isAlerted(at: coordinate, regions: boundaries, districts: districts)
            let feature = MLNPointFeature()
            feature.coordinate = CLLocationCoordinate2D(coordinate)
            feature.identifier = threat.id
            let icon = ThreatIcon(threat)
            feature.attributes = [
                Constants.iconNameKey: icon.name,
                // Unknown course draws the icon pointing north.
                Constants.headingKey: icon.rotatesWithHeading ? threat.course ?? 0 : 0,
                Constants.selectedKey: selection == .threat(id: threat.id),
                Constants.outsideAlertKey: isOutsideAlert,
                // The line break ends the label's section, so the name always starts a line of its own.
                Constants.captionLabelKey: threat.mapCaption.map { "\($0.label)\n" } ?? "",
                Constants.captionNameKey: threat.mapCaption?.name ?? ""
            ]
            return feature
        })
    }

    func applySelectedTrack() {
        guard let selectedTrackSource else { return }
        guard
            case .threat(let selectedThreatID) = selection,
            let threat = threats.first(where: { $0.id == selectedThreatID }),
            let marker = threat.markerCoordinate(coverage: alertCoverage, districts: districts)
        else {
            selectedTrackSource.shape = nil
            return
        }

        var shapes: [MLNShape] = []
        // The trail ends at the current position, so the solid line reaches the pin.
        var trailCoordinates = threat.trail.map { CLLocationCoordinate2D($0.coordinate) }
        if let position = threat.position {
            trailCoordinates.append(CLLocationCoordinate2D(position.coordinate))
        }
        if trailCoordinates.count >= 2 {
            let trail = MLNPolylineFeature(coordinates: &trailCoordinates, count: UInt(trailCoordinates.count))
            trail.attributes = [Constants.trackPartKey: Constants.trailPart]
            shapes.append(trail)
        }
        if let target = threat.target, target.coordinate != marker {
            var forecastCoordinates = [CLLocationCoordinate2D(marker), CLLocationCoordinate2D(target.coordinate)]
            let forecast = MLNPolylineFeature(coordinates: &forecastCoordinates, count: UInt(forecastCoordinates.count))
            forecast.attributes = [Constants.trackPartKey: Constants.forecastPart]
            let targetDot = MLNPointFeature()
            targetDot.coordinate = CLLocationCoordinate2D(target.coordinate)
            targetDot.attributes = [Constants.trackPartKey: Constants.targetPart]
            shapes.append(contentsOf: [forecast, targetDot])
        }
        selectedTrackSource.shape = MLNShapeCollectionFeature(shapes: shapes)
    }

    /// Outlines the selected region, or nothing.
    func applySelectedRegion() {
        guard let selectedRegionOutline else { return }
        let regionID: String
        if case .region(let id) = selection {
            regionID = id
        } else {
            regionID = ""
        }
        selectedRegionOutline.predicate = NSPredicate(format: "%K == %@", Constants.regionIDKey, regionID)
    }

    /// Screen distance from the tap to a pin, to pick the nearest of overlapping pins.
    static func distance(
        from point: CGPoint,
        to feature: MLNFeature,
        in mapView: MLNMapView
    ) -> CGFloat {
        let featurePoint = mapView.convert(feature.coordinate, toPointTo: mapView)
        return hypot(featurePoint.x - point.x, featurePoint.y - point.y)
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
            // An attribute too: filters and tap queries read attributes, not identifiers, reliably.
            feature.attributes[Constants.regionIDKey] = boundary.id
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
    static let selectedTrackSourceID = "selected-track"
    static let territoryFillLayerID = "regions-territory-fill"
    static let regionAlertFillLayerID = "regions-alert-fill"
    static let districtAlertFillLayerID = "districts-alert-fill"
    static let districtOutlineLayerID = "districts-outline"
    static let outlineLayerID = "regions-outline"
    static let selectedRegionOutlineLayerID = "regions-selected-outline"
    static let cityLayerID = "cities-labels"
    static let threatLayerID = "threats-pins"
    static let selectedTrailLayerID = "selected-track-trail"
    static let selectedForecastLayerID = "selected-track-forecast"
    static let selectedTargetLayerID = "selected-track-target"

    static let regionIDKey = "regionID"
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
    static let selectedKey = "selected"
    static let outsideAlertKey = "outsideAlert"
    static let captionLabelKey = "captionLabel"
    static let captionNameKey = "captionName"
    static let trackPartKey = "part"
    static let trailPart = "trail"
    static let forecastPart = "forecast"
    static let targetPart = "target"
    static let roundJoin = "round"
    static let mapAlignment = "map"
    static let topAnchor = "top"

    static let territoryColor = UIColor.mapTerritory
    static let territoryFillOpacity: Double = 0.55
    static let redAlertColor = UIColor.mapAlertRed
    static let yellowAlertColor = UIColor.mapAlertYellow
    static let wholeAlertFillOpacity: Double = 0.7
    static let partialAlertFillOpacity: Double = 0.35
    static let outlineOpacity: Double = 0.35
    static let outlineWidth: Double = 0.8
    static let districtOutlineOpacity: Double = 0.2
    static let districtOutlineWidth: Double = 0.5
    static let selectedRegionColor = UIColor.mapTrack
    static let selectedRegionOutlineOpacity: Double = 0.9
    static let selectedRegionOutlineWidth: Double = 2

    /// A font the OpenFreeMap glyph server provides.
    static let cityFontNames = ["Noto Sans Bold"]
    static let cityFontSize: Double = 11
    static let threatIconScale: Double = 0.75
    static let selectedThreatIconScale: Double = 1
    static let threatCaptionFontSize: Double = 11
    static let outsideAlertOpacity: Double = 0.4
    static let captionLabelFontNames = ["Noto Sans Regular"]
    static let captionLabelScale: Double = 0.8
    static let captionLabelColor = UIColor.mapCaption
    /// Below the pin, in ems of the caption font; the selected pin is drawn larger, so its caption sits lower.
    static let threatCaptionOffset = CGVector(dx: 0, dy: 1.3)
    static let selectedThreatCaptionOffset = CGVector(dx: 0, dy: 1.8)
    static let trackColor = UIColor.mapTrack
    static let trailOpacity: Double = 0.7
    static let forecastOpacity: Double = 0.55
    static let trackWidth: Double = 2
    static let forecastDashPattern: [Double] = [2, 2]
    static let targetDotRadius: Double = 5

    /// Half the side of the square a tap searches for pins: about a fingertip.
    static let tapRadius: CGFloat = 22
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
            threats: [],
            selection: nil,
            onSelect: { _ in }
        )
    }
}
