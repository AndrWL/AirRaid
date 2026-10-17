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
/// With a focused region the rest of the country is dimmed, threats outside it fade, and the camera fits the region
/// and does not let a pan wander far from it.
///
/// Regions, cities, and threats are style layers over GeoJSON sources rather than annotations: the GPU draws
/// them, and an update replaces one source instead of diffing views.
/// - Note: MapLibre is imported only in this folder; everything outside works with domain models.
struct AirRaidMapView: UIViewRepresentable {

    // MARK: - Variables

    /// The base map; a new one reloads the style and installs the map's layers again in its palette.
    let baseStyle: MapBaseStyle
    let boundaries: [RegionBoundary]
    let districts: [DistrictBoundary]
    let cities: [City]
    let alertCoverage: AirRaidCoverage
    let threats: [Threat]

    /// Threats inside the radius of one of the user's places, drawn red.
    let nearThreatIDs: Set<String>
    let selection: MapSelection?

    /// The region the map is narrowed to, or `nil` for the whole country.
    let focusedRegionID: String?

    /// Changes whenever the camera should fit the focused region (or the country) again.
    let recenterRequest: Int

    /// Draws the user's blue dot; only once the user has allowed location, or the map would ask for it on its own.
    let showsUserLocation: Bool

    /// A new request flies the camera to its point.
    let flyRequest: MapFlyRequest?

    /// While the user picks a point under a fixed centre pin: taps select nothing and the focus does not hold the
    /// camera.
    let isPickingLocation: Bool

    /// The user's location and home: a radius circle around each, and a pin on the home.
    let places: [WatchedPlace]

    /// The moment the forecast ghosts are drawn for; advanced on a timer by the view.
    let forecastDate: Date

    /// Called with the tapped pin, else the tapped region, or `nil` when a tap hits neither.
    let onSelect: (MapSelection?) -> Void

    /// Called with the point under the centre of the map whenever the camera stops, and as it moves while picking.
    let onCenterChange: (GeoCoordinate) -> Void

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        context.coordinator.baseStyle = baseStyle
        let mapView = ResizingMapView(frame: .zero, styleURL: baseStyle.styleURL)
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        // Both ornaments on the left, clear of the map buttons in the bottom-right corner.
        mapView.attributionButtonPosition = .bottomLeft
        mapView.attributionButtonMargins = MapLayerStyle.attributionButtonMargins
        let coordinator = context.coordinator
        mapView.onResize = { [weak coordinator] in
            coordinator?.didResize()
        }

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
        context.coordinator.onCenterChange = onCenterChange
        context.coordinator.update(from: self)
        if context.coordinator.baseStyle != baseStyle {
            context.coordinator.baseStyle = baseStyle
            mapView.styleURL = baseStyle.styleURL
        }
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

        /// The base style's place label layers with their original filters, narrowed once the outlines and cities are
        /// known.
        private var basePlaceLabels: [(layer: MLNSymbolStyleLayer, predicate: NSPredicate?)] = []

        /// Ukraine's outline as a `within` filter; `nil` until the outlines load.
        private var insideUkraine: [Any]?

        private var boundaries: [RegionBoundary] = []
        private var districts: [DistrictBoundary] = []
        private var cities: [City] = []
        private var alertCoverage: AirRaidCoverage = .none
        private var threats: [Threat] = []
        private var nearThreatIDs: Set<String> = []
        private var selection: MapSelection?

        /// The selected-region outline, whose filter follows the selection.
        private var selectedRegionOutline: MLNLineStyleLayer?

        private var focusedRegionID: String?
        private var recenterRequest = 0
        private var flyRequest: MapFlyRequest?
        var isPickingLocation = false

        /// Read by the places extension in its own file, hence not private.
        var places: [WatchedPlace] = []
        var placesSource: MLNShapeSource?
        var onCenterChange: (GeoCoordinate) -> Void = { _ in }

        /// Read by the forecast extension in its own file, hence not private.
        var forecastSource: MLNShapeSource?
        private var forecastDate = Date.distantPast

        weak var mapView: MLNMapView?

        /// Dims every region but the focused one.
        private var focusDimFill: MLNFillStyleLayer?

        /// The base map whose style is loaded or loading; the map's layers take its palette.
        var baseStyle: MapBaseStyle = .dark

        var palette: MapPalette {
            MapPalette(baseStyle)
        }

        /// Whether the style has loaded; the camera is fitted only after that, when the view has its size.
        private(set) var isStyleLoaded = false

        /// A point asked for before the style loaded; the camera starts there instead of on the country.
        var pendingFlyLocation: GeoCoordinate?

        /// The camera still shows the fit for the country or the focused region, so a new size fits it again.
        /// Cleared once the user moves the map or the camera flies somewhere.
        var keepsFit = false

        /// A threat, region or place sheet covers the lower half of the map.
        var isDetailsSheetShown: Bool {
            selection != nil
        }

        /// Region features by region ID, rebuilt only when the outlines change.
        private var regionFeatures: [String: MLNMultiPolygonFeature] = [:]

        /// Raion features by how alerts name them, rebuilt only when the outlines change.
        private var districtFeatures: [DistrictKey: MLNMultiPolygonFeature] = [:]

        /// Applies the view's latest data, rebuilding only the sources whose input changed.
        func update(from view: AirRaidMapView) {
            let boundariesChanged = view.boundaries.map(\.id) != boundaries.map(\.id)
            let districtsChanged = view.districts.map(\.id) != districts.map(\.id)
            let citiesChanged = view.cities != cities
            let alertsChanged = view.alertCoverage != alertCoverage
            let threatsChanged = view.threats != threats || view.nearThreatIDs != nearThreatIDs
            let selectionChanged = view.selection != selection
            let focusChanged = view.focusedRegionID != focusedRegionID
            let recenterRequested = view.recenterRequest != recenterRequest
            let flyRequested = view.flyRequest != flyRequest

            boundaries = view.boundaries
            districts = view.districts
            cities = view.cities
            alertCoverage = view.alertCoverage
            threats = view.threats
            nearThreatIDs = view.nearThreatIDs
            selection = view.selection
            focusedRegionID = view.focusedRegionID
            recenterRequest = view.recenterRequest
            flyRequest = view.flyRequest
            isPickingLocation = view.isPickingLocation
            updatePlaces(from: view, flyRequested: flyRequested)

            if boundariesChanged {
                regionFeatures = MapFeatureFactory.makeRegionFeatures(from: boundaries)
                insideUkraine = boundaries.isEmpty ? nil : BaseMapRestyler.withinExpression(boundaries.flatMap(\.polygons))
                applyBaseLabelFilters()
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
                if !flyRequested, case .threat(let id) = selection {
                    revealThreat(at: threats.first { $0.id == id }?.markerCoordinate(coverage: alertCoverage, districts: districts))
                }
            }
            updateFocus(focusChanged: focusChanged, recenterRequested: recenterRequested, boundariesChanged: boundariesChanged)
            // An area-only threat is placed by the alerts, so its pin moves when they change.
            if threatsChanged || view.forecastDate != forecastDate {
                forecastDate = view.forecastDate
                applyForecast(threats: threats, at: forecastDate)
            }
            if threatsChanged || selectionChanged || alertsChanged || districtsChanged || focusChanged {
                applyThreats()
                applySelectedTrack()
            }
        }

    }
}

// MARK: - MLNMapViewDelegate

extension AirRaidMapView.Coordinator: MLNMapViewDelegate {

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        // A new base style replaces every layer, but the camera stays where the user left it.
        let isFirstLoad = !isStyleLoaded
        // Here rather than in `makeUIView`: the view has its real size only by now, and fitting needs it.
        isStyleLoaded = true
        if isFirstLoad {
            if let location = pendingFlyLocation {
                pendingFlyLocation = nil
                showAtLaunch(location)
            } else {
                fitCamera(animated: false)
            }
        }
        installLayers(in: style)
        applyFocus()
        applyRegions()
        applyDistricts()
        applyCities()
        applySelectedRegion()
        applyPlaces()
        applyThreats()
        applySelectedTrack()
        applyForecast(threats: threats, at: forecastDate)
    }

    func mapView(
        _ mapView: MLNMapView,
        regionWillChangeWith reason: MLNCameraChangeReason,
        animated: Bool
    ) {
        if !reason.isEmpty, !reason.contains(.programmatic) {
            keepsFit = false
        }
    }

    /// Also while the camera is still moving: "here" may be tapped before a fling has settled.
    func mapViewRegionIsChanging(_ mapView: MLNMapView) {
        guard isPickingLocation else { return }
        onCenterChange(GeoCoordinate(mapView.centerCoordinate))
    }

    func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        onCenterChange(GeoCoordinate(mapView.centerCoordinate))
    }

    /// Keeps a pan from leaving the focused region: the centre may stray a quarter of the region's size past its box.
    func mapView(
        _ mapView: MLNMapView,
        shouldChangeFrom oldCamera: MLNMapCamera,
        to newCamera: MLNMapCamera
    ) -> Bool {
        guard !isPickingLocation, let box = focusedRegion?.boundingBox else { return true }
        return box.contains(GeoCoordinate(newCamera.centerCoordinate), margin: MapLayerStyle.focusPanMargin)
    }
}

// MARK: - Resize

extension AirRaidMapView.Coordinator {

    /// Fits the camera to the new size until the user has moved it.
    func didResize() {
        guard keepsFit else { return }
        fitCamera(animated: false)
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

        BaseMapRestyler.restyle(style, palette: palette)
        basePlaceLabels = BaseMapRestyler.labelLayersInsideUkraine(in: style).map { ($0, $0.predicate) }

        installRegionLayers(in: style, regionSource: regionSource, districtSource: districtSource)
        installCityLayer(in: style, source: citySource)
        installPlacesLayers(in: style)
        installSelectedTrackLayers(in: style, source: selectedTrackSource)
        installThreatLayer(in: style, source: threatSource)
        installForecastLayers(in: style)
    }

    func installRegionLayers(
        in style: MLNStyle,
        regionSource: MLNShapeSource,
        districtSource: MLNShapeSource
    ) {
        // Tints the whole country, so Ukraine stands out from the dark base map.
        let territoryFill = MLNFillStyleLayer(identifier: MapLayerStyle.territoryFillLayerID, source: regionSource)
        territoryFill.fillColor = NSExpression(forConstantValue: palette.territory)
        territoryFill.fillOpacity = NSExpression(forConstantValue: palette.territoryOpacity)

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
        let districtOutline = MapFeatureFactory.makeOutline(
            identifier: MapLayerStyle.districtOutlineLayerID,
            source: districtSource,
            color: palette.outline,
            opacity: MapLayerStyle.districtOutlineOpacity,
            width: MapLayerStyle.districtOutlineWidth
        )
        let outline = MapFeatureFactory.makeOutline(
            identifier: MapLayerStyle.outlineLayerID,
            source: regionSource,
            color: palette.outline,
            opacity: MapLayerStyle.outlineOpacity,
            width: MapLayerStyle.outlineWidth
        )

        // Below the first label layer, so the base map's names stay readable over the fill.
        let regionLayers = [
            territoryFill, regionAlertFill, districtAlertFill, makeFocusDim(source: regionSource), districtOutline, outline
        ] + makeHighlightOutlines(source: regionSource)
        if let firstLabelLayer = style.layers.first(where: { $0 is MLNSymbolStyleLayer }) {
            regionLayers.forEach { style.insertLayer($0, below: firstLabelLayer) }
        } else {
            regionLayers.forEach(style.addLayer)
        }
    }

    /// Over the alert fills, so the rest of the country reads as background, but under the outlines.
    func makeFocusDim(source: MLNShapeSource) -> MLNFillStyleLayer {
        let dimFill = MLNFillStyleLayer(identifier: MapLayerStyle.focusDimLayerID, source: source)
        dimFill.fillColor = NSExpression(forConstantValue: palette.focusDim)
        dimFill.fillOpacity = NSExpression(forConstantValue: MapLayerStyle.focusDimOpacity)
        dimFill.predicate = Self.matchesNoRegion
        focusDimFill = dimFill
        return dimFill
    }

    /// The selected region's outline.
    func makeHighlightOutlines(source: MLNShapeSource) -> [MLNLineStyleLayer] {
        let selectedOutline = MapFeatureFactory.makeOutline(
            identifier: MapLayerStyle.selectedRegionOutlineLayerID,
            source: source,
            color: palette.track,
            opacity: MapLayerStyle.selectedRegionOutlineOpacity,
            width: MapLayerStyle.selectedRegionOutlineWidth
        )
        selectedRegionOutline = selectedOutline
        return [selectedOutline]
    }

    func installCityLayer(in style: MLNStyle, source: MLNShapeSource) {
        let cityLabels = MLNSymbolStyleLayer(identifier: MapLayerStyle.cityLayerID, source: source)
        cityLabels.text = NSExpression(forKeyPath: MapLayerStyle.nameKey)
        cityLabels.textFontNames = NSExpression(forConstantValue: MapLayerStyle.cityFontNames)
        cityLabels.textFontSize = NSExpression(forConstantValue: MapLayerStyle.cityFontSize)
        cityLabels.textColor = NSExpression(forConstantValue: palette.label)
        cityLabels.textHaloColor = NSExpression(forConstantValue: palette.halo)
        cityLabels.textHaloWidth = NSExpression(forConstantValue: MapLayerStyle.cityHaloWidth)
        style.addLayer(cityLabels)
    }

    func installThreatLayer(in style: MLNStyle, source: MLNShapeSource) {
        for icon in ThreatIcon.allCases {
            style.setImage(icon.image, forName: icon.name)
            style.setImage(icon.nearImage, forName: icon.nearName)
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
        let pinOpacity = MapFeatureFactory.makePinOpacity()
        threatPins.iconOpacity = pinOpacity
        threatPins.textOpacity = pinOpacity

        // The caption under the pin; captions that would collide are hidden, the pins always stay.
        let captionLabel = MLNAttributedExpression(
            NSExpression(forKeyPath: MapLayerStyle.captionLabelKey),
            attributes: [
                .fontNamesAttribute: NSExpression(forConstantValue: MapLayerStyle.captionLabelFontNames),
                .fontScaleAttribute: NSExpression(forConstantValue: MapLayerStyle.captionLabelScale),
                .fontColorAttribute: NSExpression(forConstantValue: palette.caption)
            ]
        )
        let captionName = MLNAttributedExpression(NSExpression(forKeyPath: MapLayerStyle.captionNameKey))
        threatPins.text = NSExpression(forAttributedExpressions: [captionLabel, captionName].map {
            NSExpression(forConstantValue: $0)
        })
        threatPins.textFontNames = NSExpression(forConstantValue: MapLayerStyle.cityFontNames)
        threatPins.textFontSize = NSExpression(forConstantValue: MapLayerStyle.threatCaptionFontSize)
        threatPins.textColor = NSExpression(forConstantValue: palette.label)
        threatPins.textHaloColor = NSExpression(forConstantValue: palette.halo)
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
        trail.lineColor = NSExpression(forConstantValue: palette.track)
        trail.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.trailOpacity)
        trail.lineWidth = NSExpression(forConstantValue: MapLayerStyle.trackWidth)
        trail.lineJoin = NSExpression(forConstantValue: MapLayerStyle.roundJoin)

        let forecast = MLNLineStyleLayer(identifier: MapLayerStyle.selectedForecastLayerID, source: source)
        forecast.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.trackPartKey, MapLayerStyle.forecastPart)
        forecast.lineColor = NSExpression(forConstantValue: palette.track)
        forecast.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.forecastOpacity)
        forecast.lineWidth = NSExpression(forConstantValue: MapLayerStyle.trackWidth)
        forecast.lineDashPattern = NSExpression(forConstantValue: MapLayerStyle.forecastDashPattern)

        let targetDot = MLNCircleStyleLayer(identifier: MapLayerStyle.selectedTargetLayerID, source: source)
        targetDot.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.trackPartKey, MapLayerStyle.targetPart)
        targetDot.circleRadius = NSExpression(forConstantValue: MapLayerStyle.targetDotRadius)
        targetDot.circleColor = NSExpression(forConstantValue: UIColor.clear)
        targetDot.circleStrokeColor = NSExpression(forConstantValue: palette.track)
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

        applyBaseLabelFilters()
    }

    /// Names on the base map only inside Ukraine: the cities and countries around it would only crowd the map. The
    /// base map also labels some of the cities the map labels itself (Kyiv); those are dropped so each name appears
    /// once. Until the outlines load every label stays, rather than the whole map going blank for a moment.
    func applyBaseLabelFilters() {
        let notOurCity: [Any] = ["!", ["in", ["get", BaseMapRestyler.localNameKey], ["literal", cities.map(\.name)]]]
        for (layer, originalPredicate) in basePlaceLabels {
            var conditions: [Any] = []
            if let originalPredicate {
                conditions.append(originalPredicate.mgl_jsonExpressionObject)
            }
            if let insideUkraine {
                conditions.append(insideUkraine)
            }
            if BaseMapRestyler.isCityLabel(layer), !cities.isEmpty {
                conditions.append(notOurCity)
            }
            layer.predicate = conditions.isEmpty ? nil : NSPredicate(mglJSONObject: ["all"] + conditions)
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
                MapLayerStyle.iconNameKey: nearThreatIDs.contains(threat.id) ? icon.nearName : icon.name,
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
        keepsFit = true
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

    /// Dims for a new focus and fits the camera to it, or again when asked.
    func updateFocus(
        focusChanged: Bool,
        recenterRequested: Bool,
        boundariesChanged: Bool
    ) {
        if focusChanged {
            applyFocus()
        }
        // The region's outline may arrive after the focus did.
        if focusChanged || recenterRequested || boundariesChanged && focusedRegionID != nil {
            fitCamera(animated: true)
        }
    }

    /// A filter no region passes. MapLibre rejects `FALSEPREDICATE` as a layer filter, so it compares with an id no
    /// region has.
    static var matchesNoRegion: NSPredicate {
        NSPredicate(format: "%K == %@", MapLayerStyle.regionIDKey, "")
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
            baseStyle: .dark,
            boundaries: [],
            districts: [],
            cities: [],
            alertCoverage: .none,
            threats: [],
            nearThreatIDs: [],
            selection: nil,
            focusedRegionID: nil,
            recenterRequest: 0,
            showsUserLocation: false,
            flyRequest: nil,
            isPickingLocation: false,
            places: [],
            forecastDate: .now,
            onSelect: { _ in },
            onCenterChange: { _ in }
        )
    }
}
