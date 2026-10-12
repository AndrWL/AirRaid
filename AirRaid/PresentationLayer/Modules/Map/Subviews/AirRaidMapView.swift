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
/// it, which gets a bright outline. Regions the user follows are outlined in the accent colour.
///
/// With a focused region the rest of the country is dimmed, threats outside it fade, and the camera fits the region
/// and does not let a pan wander far from it.
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

    /// ISO codes of the regions the user follows.
    let favoriteRegionIDs: [String]

    /// The region the map is narrowed to, or `nil` for the whole country.
    let focusedRegionID: String?

    /// Changes whenever the camera should fit the focused region (or the country) again.
    let recenterRequest: Int

    /// Called with the tapped pin, else the tapped region, or `nil` when a tap hits neither.
    let onSelect: (MapSelection?) -> Void

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
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
        context.coordinator.update(from: self)
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

        private var favoriteRegionIDs: [String] = []
        private var focusedRegionID: String?
        private var recenterRequest = 0

        weak var mapView: MLNMapView?

        /// Dims every region but the focused one.
        private var focusDimFill: MLNFillStyleLayer?

        /// Whether the style has loaded; the camera is fitted only after that, when the view has its size.
        private var isStyleLoaded = false

        /// The followed-regions outline, whose filter follows the favourites.
        private var favoriteRegionOutline: MLNLineStyleLayer?

        /// Region features by region ID, rebuilt only when the outlines change.
        private var regionFeatures: [String: MLNMultiPolygonFeature] = [:]

        /// Raion features by how alerts name them, rebuilt only when the outlines change.
        private var districtFeatures: [DistrictKey: MLNMultiPolygonFeature] = [:]

        /// Applies the view's latest data, rebuilding only the sources whose input changed.
        func update(from view: AirRaidMapView) {
            let boundaries = view.boundaries
            let districts = view.districts
            let cities = view.cities
            let alertCoverage = view.alertCoverage
            let threats = view.threats
            let selection = view.selection
            let favoriteRegionIDs = view.favoriteRegionIDs
            let focusChanged = view.focusedRegionID != focusedRegionID
            let recenterRequested = view.recenterRequest != recenterRequest

            let boundariesChanged = boundaries.map(\.id) != self.boundaries.map(\.id)
            let districtsChanged = districts.map(\.id) != self.districts.map(\.id)
            let citiesChanged = cities != self.cities
            let alertsChanged = alertCoverage != self.alertCoverage
            let threatsChanged = threats != self.threats
            let selectionChanged = selection != self.selection
            let favoritesChanged = favoriteRegionIDs != self.favoriteRegionIDs

            self.boundaries = boundaries
            self.districts = districts
            self.cities = cities
            self.alertCoverage = alertCoverage
            self.threats = threats
            self.selection = selection
            self.favoriteRegionIDs = favoriteRegionIDs
            focusedRegionID = view.focusedRegionID
            recenterRequest = view.recenterRequest

            if boundariesChanged {
                regionFeatures = MapFeatureFactory.makeRegionFeatures(from: boundaries)
            }
            if boundariesChanged || alertsChanged {
                applyRegions()
            }
            if districtsChanged {
                districtFeatures = MapFeatureFactory.makeDistrictFeatures(from: districts)
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
            if favoritesChanged {
                applyFavoriteRegions()
            }
            if focusChanged {
                applyFocus()
            }
            // The region's outline may arrive after the focus did.
            if focusChanged || recenterRequested || boundariesChanged && focusedRegionID != nil {
                fitCamera(animated: true)
            }
            // An area-only threat is placed by the alerts, so its pin moves when they change.
            if threatsChanged || selectionChanged || alertsChanged || districtsChanged || focusChanged {
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
                x: point.x - MapLayerStyle.tapRadius,
                y: point.y - MapLayerStyle.tapRadius,
                width: MapLayerStyle.tapRadius * 2,
                height: MapLayerStyle.tapRadius * 2
            )
            let nearest = mapView.visibleFeatures(in: hitArea, styleLayerIdentifiers: [MapLayerStyle.threatLayerID])
                .min { lhs, rhs in
                    Self.distance(from: point, to: lhs, in: mapView) < Self.distance(from: point, to: rhs, in: mapView)
                }
            if let threatID = nearest?.identifier as? String {
                onSelect(.threat(id: threatID))
                return
            }
            let region = mapView.visibleFeatures(at: point, styleLayerIdentifiers: [MapLayerStyle.territoryFillLayerID]).first
            onSelect((region?.attributes[MapLayerStyle.regionIDKey] as? String).map { .region(id: $0) })
        }
    }
}

// MARK: - MLNMapViewDelegate

extension AirRaidMapView.Coordinator: MLNMapViewDelegate {

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        // Here rather than in `makeUIView`: the view has its real size only by now, and fitting needs it.
        isStyleLoaded = true
        fitCamera(animated: false)
        installLayers(in: style)
        applyFocus()
        applyRegions()
        applyDistricts()
        applyCities()
        applySelectedRegion()
        applyFavoriteRegions()
        applyThreats()
        applySelectedTrack()
    }

    /// Keeps a pan from leaving the focused region: the centre may stray a quarter of the region's size past its box.
    func mapView(
        _ mapView: MLNMapView,
        shouldChangeFrom oldCamera: MLNMapCamera,
        to newCamera: MLNMapCamera
    ) -> Bool {
        guard let box = focusedRegion?.boundingBox else { return true }
        return box.contains(GeoCoordinate(newCamera.centerCoordinate), margin: MapLayerStyle.focusPanMargin)
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
        let regionSource = MLNShapeSource(identifier: MapLayerStyle.regionSourceID, shape: nil)
        let districtSource = MLNShapeSource(identifier: MapLayerStyle.districtSourceID, shape: nil)
        let citySource = MLNShapeSource(identifier: MapLayerStyle.citySourceID, shape: nil)
        let threatSource = MLNShapeSource(identifier: MapLayerStyle.threatSourceID, shape: nil)
        let selectedTrackSource = MLNShapeSource(identifier: MapLayerStyle.selectedTrackSourceID, shape: nil)
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
        let territoryFill = MLNFillStyleLayer(identifier: MapLayerStyle.territoryFillLayerID, source: regionSource)
        territoryFill.fillColor = NSExpression(forConstantValue: MapLayerStyle.territoryColor)
        territoryFill.fillOpacity = NSExpression(forConstantValue: MapLayerStyle.territoryFillOpacity)

        let regionAlertFill = MapFeatureFactory.makeAlertFill(
            identifier: MapLayerStyle.regionAlertFillLayerID,
            source: regionSource,
            opacity: NSExpression(forConstantValue: MapLayerStyle.wholeAlertFillOpacity)
        )
        // A raion alert is filled as strongly as an oblast one; a hromada inside the raion only faintly.
        let districtAlertFill = MapFeatureFactory.makeAlertFill(
            identifier: MapLayerStyle.districtAlertFillLayerID,
            source: districtSource,
            opacity: NSExpression(
                forMLNMatchingKey: NSExpression(forKeyPath: MapLayerStyle.alertExtentKey),
                in: [
                    NSExpression(forConstantValue: MapLayerStyle.wholeExtent):
                        NSExpression(forConstantValue: MapLayerStyle.wholeAlertFillOpacity)
                ],
                default: NSExpression(forConstantValue: MapLayerStyle.partialAlertFillOpacity)
            )
        )

        // Raion borders only inside alerted raions, so the alerted part reads as such without cluttering the map.
        let districtOutline = MLNLineStyleLayer(identifier: MapLayerStyle.districtOutlineLayerID, source: districtSource)
        districtOutline.lineColor = NSExpression(forConstantValue: UIColor.mapOutline)
        districtOutline.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.districtOutlineOpacity)
        districtOutline.lineWidth = NSExpression(forConstantValue: MapLayerStyle.districtOutlineWidth)

        let outline = MLNLineStyleLayer(identifier: MapLayerStyle.outlineLayerID, source: regionSource)
        outline.lineColor = NSExpression(forConstantValue: UIColor.mapOutline)
        outline.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.outlineOpacity)
        outline.lineWidth = NSExpression(forConstantValue: MapLayerStyle.outlineWidth)

        // Over the alert fills, so the rest of the country reads as background, but under the outlines.
        let dimFill = MLNFillStyleLayer(identifier: MapLayerStyle.focusDimLayerID, source: regionSource)
        dimFill.fillColor = NSExpression(forConstantValue: MapLayerStyle.focusDimColor)
        dimFill.fillOpacity = NSExpression(forConstantValue: MapLayerStyle.focusDimOpacity)
        dimFill.predicate = Self.matchesNoRegion
        focusDimFill = dimFill

        let favoriteOutline = MLNLineStyleLayer(identifier: MapLayerStyle.favoriteRegionOutlineLayerID, source: regionSource)
        favoriteOutline.lineColor = NSExpression(forConstantValue: MapLayerStyle.favoriteRegionColor)
        favoriteOutline.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.favoriteRegionOutlineOpacity)
        favoriteOutline.lineWidth = NSExpression(forConstantValue: MapLayerStyle.favoriteRegionOutlineWidth)
        favoriteOutline.lineJoin = NSExpression(forConstantValue: MapLayerStyle.roundJoin)
        favoriteRegionOutline = favoriteOutline

        let selectedOutline = MLNLineStyleLayer(identifier: MapLayerStyle.selectedRegionOutlineLayerID, source: regionSource)
        selectedOutline.lineColor = NSExpression(forConstantValue: MapLayerStyle.selectedRegionColor)
        selectedOutline.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.selectedRegionOutlineOpacity)
        selectedOutline.lineWidth = NSExpression(forConstantValue: MapLayerStyle.selectedRegionOutlineWidth)
        selectedOutline.lineJoin = NSExpression(forConstantValue: MapLayerStyle.roundJoin)
        selectedRegionOutline = selectedOutline

        // Below the first label layer, so the base map's names stay readable over the fill.
        let regionLayers = [
            territoryFill, regionAlertFill, districtAlertFill, dimFill, districtOutline, outline, favoriteOutline,
            selectedOutline
        ]
        if let firstLabelLayer = style.layers.first(where: { $0 is MLNSymbolStyleLayer }) {
            regionLayers.forEach { style.insertLayer($0, below: firstLabelLayer) }
        } else {
            regionLayers.forEach(style.addLayer)
        }
    }

    func installCityLayer(in style: MLNStyle, source: MLNShapeSource) {
        let cityLabels = MLNSymbolStyleLayer(identifier: MapLayerStyle.cityLayerID, source: source)
        cityLabels.text = NSExpression(forKeyPath: MapLayerStyle.nameKey)
        cityLabels.textFontNames = NSExpression(forConstantValue: MapLayerStyle.cityFontNames)
        cityLabels.textFontSize = NSExpression(forConstantValue: MapLayerStyle.cityFontSize)
        cityLabels.textColor = NSExpression(forConstantValue: UIColor.mapLabel)
        cityLabels.textHaloColor = NSExpression(forConstantValue: UIColor.mapHalo)
        cityLabels.textHaloWidth = NSExpression(forConstantValue: MapLayerStyle.cityHaloWidth)
        style.addLayer(cityLabels)
    }

    func installThreatLayer(in style: MLNStyle, source: MLNShapeSource) {
        for icon in ThreatIcon.allCases {
            style.setImage(icon.image, forName: icon.name)
        }
        let threatPins = MLNSymbolStyleLayer(identifier: MapLayerStyle.threatLayerID, source: source)
        threatPins.iconImageName = NSExpression(forKeyPath: MapLayerStyle.iconNameKey)
        threatPins.iconRotation = NSExpression(forKeyPath: MapLayerStyle.headingKey)
        threatPins.iconRotationAlignment = NSExpression(forConstantValue: MapLayerStyle.mapAlignment)
        threatPins.iconScale = NSExpression(
            forMLNConditional: NSPredicate(format: "%K == YES", MapLayerStyle.selectedKey),
            trueExpression: NSExpression(forConstantValue: MapLayerStyle.selectedThreatIconScale),
            falseExpression: NSExpression(forConstantValue: MapLayerStyle.threatIconScale)
        )
        threatPins.iconAllowsOverlap = NSExpression(forConstantValue: true)
        threatPins.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        // A pin where there is no alert is probably misplaced (a namesake in another oblast): faded, not hidden.
        // A pin outside the focused region fades further: it is context, not what the user is watching.
        let pinOpacity = NSExpression(
            forMLNConditional: NSPredicate(format: "%K == YES", MapLayerStyle.outsideFocusKey),
            trueExpression: NSExpression(forConstantValue: MapLayerStyle.outsideFocusOpacity),
            falseExpression: NSExpression(
                forMLNConditional: NSPredicate(format: "%K == YES", MapLayerStyle.outsideAlertKey),
                trueExpression: NSExpression(forConstantValue: MapLayerStyle.outsideAlertOpacity),
                falseExpression: NSExpression(forConstantValue: 1)
            )
        )
        threatPins.iconOpacity = pinOpacity
        threatPins.textOpacity = pinOpacity

        // The caption under the pin; captions that would collide are hidden, the pins always stay.
        let captionLabel = MLNAttributedExpression(
            NSExpression(forKeyPath: MapLayerStyle.captionLabelKey),
            attributes: [
                .fontNamesAttribute: NSExpression(forConstantValue: MapLayerStyle.captionLabelFontNames),
                .fontScaleAttribute: NSExpression(forConstantValue: MapLayerStyle.captionLabelScale),
                .fontColorAttribute: NSExpression(forConstantValue: MapLayerStyle.captionLabelColor)
            ]
        )
        let captionName = MLNAttributedExpression(NSExpression(forKeyPath: MapLayerStyle.captionNameKey))
        threatPins.text = NSExpression(forAttributedExpressions: [captionLabel, captionName].map {
            NSExpression(forConstantValue: $0)
        })
        threatPins.textFontNames = NSExpression(forConstantValue: MapLayerStyle.cityFontNames)
        threatPins.textFontSize = NSExpression(forConstantValue: MapLayerStyle.threatCaptionFontSize)
        threatPins.textColor = NSExpression(forConstantValue: UIColor.mapLabel)
        threatPins.textHaloColor = NSExpression(forConstantValue: UIColor.mapHalo)
        threatPins.textHaloWidth = NSExpression(forConstantValue: MapLayerStyle.cityHaloWidth)
        threatPins.textAnchor = NSExpression(forConstantValue: MapLayerStyle.topAnchor)
        threatPins.textOffset = NSExpression(
            forMLNConditional: NSPredicate(format: "%K == YES", MapLayerStyle.selectedKey),
            trueExpression: NSExpression(forConstantValue: NSValue(cgVector: MapLayerStyle.selectedThreatCaptionOffset)),
            falseExpression: NSExpression(forConstantValue: NSValue(cgVector: MapLayerStyle.threatCaptionOffset))
        )
        threatPins.textOptional = NSExpression(forConstantValue: true)
        threatPins.textAllowsOverlap = NSExpression(forConstantValue: false)
        style.addLayer(threatPins)
    }

    /// The selected threat's path: where it has been (solid) and where it is heading (dashed).
    func installSelectedTrackLayers(in style: MLNStyle, source: MLNShapeSource) {
        let trail = MLNLineStyleLayer(identifier: MapLayerStyle.selectedTrailLayerID, source: source)
        trail.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.trackPartKey, MapLayerStyle.trailPart)
        trail.lineColor = NSExpression(forConstantValue: MapLayerStyle.trackColor)
        trail.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.trailOpacity)
        trail.lineWidth = NSExpression(forConstantValue: MapLayerStyle.trackWidth)
        trail.lineJoin = NSExpression(forConstantValue: MapLayerStyle.roundJoin)

        let forecast = MLNLineStyleLayer(identifier: MapLayerStyle.selectedForecastLayerID, source: source)
        forecast.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.trackPartKey, MapLayerStyle.forecastPart)
        forecast.lineColor = NSExpression(forConstantValue: MapLayerStyle.trackColor)
        forecast.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.forecastOpacity)
        forecast.lineWidth = NSExpression(forConstantValue: MapLayerStyle.trackWidth)
        forecast.lineDashPattern = NSExpression(forConstantValue: MapLayerStyle.forecastDashPattern)

        let targetDot = MLNCircleStyleLayer(identifier: MapLayerStyle.selectedTargetLayerID, source: source)
        targetDot.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.trackPartKey, MapLayerStyle.targetPart)
        targetDot.circleRadius = NSExpression(forConstantValue: MapLayerStyle.targetDotRadius)
        targetDot.circleColor = NSExpression(forConstantValue: UIColor.clear)
        targetDot.circleStrokeColor = NSExpression(forConstantValue: MapLayerStyle.trackColor)
        targetDot.circleStrokeWidth = NSExpression(forConstantValue: MapLayerStyle.trackWidth)
        targetDot.circleStrokeOpacity = NSExpression(forConstantValue: MapLayerStyle.forecastOpacity)

        [trail, forecast, targetDot].forEach(style.addLayer)
    }

    func applyRegions() {
        guard let regionSource else { return }
        for (regionID, feature) in regionFeatures {
            let level = alertCoverage.regions[regionID]
            feature.attributes[MapLayerStyle.alertLevelKey] = level.map(MapFeatureFactory.value) ?? MapLayerStyle.noAlert
        }
        regionSource.shape = MLNShapeCollectionFeature(shapes: Array(regionFeatures.values))
    }

    func applyCities() {
        guard let citySource else { return }
        citySource.shape = MLNShapeCollectionFeature(shapes: cities.map { city in
            let feature = MLNPointFeature()
            feature.coordinate = CLLocationCoordinate2D(city.coordinate)
            feature.attributes = [MapLayerStyle.nameKey: city.name]
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
            let isOutsideFocus = focusedRegion.map { !$0.contains(coordinate) } ?? false
            let feature = MLNPointFeature()
            feature.coordinate = CLLocationCoordinate2D(coordinate)
            feature.identifier = threat.id
            let icon = ThreatIcon(threat)
            feature.attributes = [
                MapLayerStyle.iconNameKey: icon.name,
                // Unknown course draws the icon pointing north.
                MapLayerStyle.headingKey: icon.rotatesWithHeading ? threat.course ?? 0 : 0,
                MapLayerStyle.selectedKey: selection == .threat(id: threat.id),
                MapLayerStyle.outsideAlertKey: isOutsideAlert,
                MapLayerStyle.outsideFocusKey: isOutsideFocus,
                // The line break ends the label's section, so the name always starts a line of its own.
                MapLayerStyle.captionLabelKey: threat.mapCaption.map { "\($0.label)\n" } ?? "",
                MapLayerStyle.captionNameKey: threat.mapCaption?.name ?? ""
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
            trail.attributes = [MapLayerStyle.trackPartKey: MapLayerStyle.trailPart]
            shapes.append(trail)
        }
        if let target = threat.target, target.coordinate != marker {
            var forecastCoordinates = [CLLocationCoordinate2D(marker), CLLocationCoordinate2D(target.coordinate)]
            let forecast = MLNPolylineFeature(coordinates: &forecastCoordinates, count: UInt(forecastCoordinates.count))
            forecast.attributes = [MapLayerStyle.trackPartKey: MapLayerStyle.forecastPart]
            let targetDot = MLNPointFeature()
            targetDot.coordinate = CLLocationCoordinate2D(target.coordinate)
            targetDot.attributes = [MapLayerStyle.trackPartKey: MapLayerStyle.targetPart]
            shapes.append(contentsOf: [forecast, targetDot])
        }
        selectedTrackSource.shape = MLNShapeCollectionFeature(shapes: shapes)
    }

    /// Outlines the selected region, or nothing.
    func applySelectedRegion() {
        guard let selectedRegionOutline else { return }
        if case .region(let id) = selection {
            selectedRegionOutline.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.regionIDKey, id)
        } else {
            selectedRegionOutline.predicate = Self.matchesNoRegion
        }
    }

    /// The focused region's outline, or `nil` with no focus or before the outlines load.
    var focusedRegion: RegionBoundary? {
        focusedRegionID.flatMap { id in boundaries.first { $0.id == id } }
    }

    func applyFocus() {
        focusDimFill?.predicate = focusedRegionID.map { NSPredicate(format: "%K != %@", MapLayerStyle.regionIDKey, $0) }
            ?? Self.matchesNoRegion
    }

    /// Fits the focused region, or the whole country without a focus.
    func fitCamera(animated: Bool) {
        guard isStyleLoaded, let mapView else { return }
        if let box = focusedRegion?.boundingBox {
            mapView.setVisibleCoordinateBounds(
                MLNCoordinateBounds(sw: CLLocationCoordinate2D(box.southWest), ne: CLLocationCoordinate2D(box.northEast)),
                edgePadding: MapLayerStyle.focusEdgePadding,
                animated: animated,
                completionHandler: nil
            )
        } else {
            mapView.setVisibleCoordinateBounds(
                MapLayerStyle.ukraineBounds,
                edgePadding: MapLayerStyle.ukraineEdgePadding,
                animated: animated,
                completionHandler: nil
            )
        }
    }

    func applyFavoriteRegions() {
        favoriteRegionOutline?.predicate = favoriteRegionIDs.isEmpty
            ? Self.matchesNoRegion
            : NSPredicate(format: "%K IN %@", MapLayerStyle.regionIDKey, favoriteRegionIDs)
    }

    /// A filter no region passes. MapLibre rejects `FALSEPREDICATE` and an empty `IN` list, so it compares with an id
    /// no region has.
    static var matchesNoRegion: NSPredicate {
        NSPredicate(format: "%K == %@", MapLayerStyle.regionIDKey, "")
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
            feature.attributes[MapLayerStyle.alertLevelKey] = MapFeatureFactory.value(of: coverage.level)
            feature.attributes[MapLayerStyle.alertExtentKey] = MapFeatureFactory.value(of: coverage.extent)
            return feature
        }
        districtSource.shape = MLNShapeCollectionFeature(shapes: alerted)
    }
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
            favoriteRegionIDs: [],
            focusedRegionID: nil,
            recenterRequest: 0,
            onSelect: { _ in }
        )
    }
}
