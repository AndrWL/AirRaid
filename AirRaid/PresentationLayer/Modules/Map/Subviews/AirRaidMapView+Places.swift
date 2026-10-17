//
//  AirRaidMapView+Places.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import MapLibre

/// The user's watched places: a faint circle for each radius and a captioned pin on each saved place — a house for the
/// home, a pin for the others. The user's own position is MapLibre's blue dot, so only its circle is drawn here.
extension AirRaidMapView.Coordinator {

    func installPlacesLayers(in style: MLNStyle) {
        let source = MLNShapeSource(identifier: MapLayerStyle.placesSourceID, shape: nil)
        style.addSource(source)
        placesSource = source
        style.setImage(MapLayerStyle.homeIcon, forName: MapLayerStyle.homeIconName)
        style.setImage(MapLayerStyle.savedPlaceIcon, forName: MapLayerStyle.savedPlaceIconName)

        let radiusFill = MLNFillStyleLayer(identifier: MapLayerStyle.placeRadiusFillLayerID, source: source)
        radiusFill.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.placePartKey, MapLayerStyle.radiusPart)
        radiusFill.fillColor = Self.placeColorExpression
        radiusFill.fillOpacity = NSExpression(forConstantValue: MapLayerStyle.placeRadiusFillOpacity)

        // One line per kind of place, each in its own colour, so they read apart where they overlap.
        let locationOutline = makeRadiusOutline(
            identifier: MapLayerStyle.placeRadiusOutlineLayerID,
            source: source,
            kind: MapLayerStyle.currentLocationKind,
            color: MapLayerStyle.currentLocationColor
        )
        let homeOutline = makeRadiusOutline(
            identifier: MapLayerStyle.homeRadiusOutlineLayerID,
            source: source,
            kind: MapLayerStyle.homeKind,
            color: MapLayerStyle.homeColor
        )
        let customOutline = makeRadiusOutline(
            identifier: MapLayerStyle.customRadiusOutlineLayerID,
            source: source,
            kind: MapLayerStyle.customKind,
            color: MapLayerStyle.savedPlaceColor
        )

        let pins = MLNSymbolStyleLayer(identifier: MapLayerStyle.placePinLayerID, source: source)
        pins.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.placePartKey, MapLayerStyle.pinPart)
        pins.iconImageName = NSExpression(
            forMLNMatchingKey: NSExpression(forKeyPath: MapLayerStyle.placeKindKey),
            in: [NSExpression(forConstantValue: MapLayerStyle.homeKind): NSExpression(forConstantValue: MapLayerStyle.homeIconName)],
            default: NSExpression(forConstantValue: MapLayerStyle.savedPlaceIconName)
        )
        pins.iconAllowsOverlap = NSExpression(forConstantValue: true)
        pins.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        // «Дім · Ірпінь», «Робота» under the pin, like a threat's caption; hidden rather than overlapping other labels.
        pins.text = NSExpression(forKeyPath: MapLayerStyle.pinCaptionKey)
        pins.textFontNames = NSExpression(forConstantValue: MapLayerStyle.cityFontNames)
        pins.textFontSize = NSExpression(forConstantValue: MapLayerStyle.threatCaptionFontSize)
        pins.textColor = Self.placeColorExpression
        pins.textHaloColor = NSExpression(forConstantValue: palette.halo)
        pins.textHaloWidth = NSExpression(forConstantValue: MapLayerStyle.cityHaloWidth)
        pins.textAnchor = NSExpression(forConstantValue: MapLayerStyle.topAnchor)
        pins.textOffset = NSExpression(forConstantValue: NSValue(cgVector: MapLayerStyle.pinCaptionOffset))
        pins.textOptional = NSExpression(forConstantValue: true)

        [radiusFill, locationOutline, homeOutline, customOutline, pins].forEach(style.addLayer)
    }

    /// Each kind of place in its own colour.
    static var placeColorExpression: NSExpression {
        NSExpression(
            forMLNMatchingKey: NSExpression(forKeyPath: MapLayerStyle.placeKindKey),
            in: [
                NSExpression(forConstantValue: MapLayerStyle.homeKind): NSExpression(forConstantValue: MapLayerStyle.homeColor),
                NSExpression(forConstantValue: MapLayerStyle.customKind): NSExpression(forConstantValue: MapLayerStyle.savedPlaceColor)
            ],
            default: NSExpression(forConstantValue: MapLayerStyle.currentLocationColor)
        )
    }

    func makeRadiusOutline(
        identifier: String,
        source: MLNShapeSource,
        kind: String,
        color: UIColor
    ) -> MLNLineStyleLayer {
        let outline = MapFeatureFactory.makeOutline(
            identifier: identifier,
            source: source,
            color: color,
            opacity: MapLayerStyle.placeRadiusOutlineOpacity,
            width: MapLayerStyle.placeRadiusOutlineWidth
        )
        outline.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", MapLayerStyle.placePartKey, MapLayerStyle.radiusPart),
            NSPredicate(format: "%K == %@", MapLayerStyle.placeKindKey, kind)
        ])
        return outline
    }

    func applyPlaces() {
        guard let placesSource else { return }
        var shapes: [MLNShape] = places.map { place in
            var ring = place.coordinate.circle(radiusKm: place.radiusKm).map(CLLocationCoordinate2D.init)
            let circle = MLNPolygonFeature(coordinates: &ring, count: UInt(ring.count))
            circle.attributes = [
                MapLayerStyle.placePartKey: MapLayerStyle.radiusPart,
                MapLayerStyle.placeKindKey: Self.layerKind(of: place)
            ]
            return circle
        }
        for place in places where place.kind != .currentLocation {
            let pin = MLNPointFeature()
            pin.coordinate = CLLocationCoordinate2D(place.coordinate)
            pin.attributes = [
                MapLayerStyle.placePartKey: MapLayerStyle.pinPart,
                MapLayerStyle.placeKindKey: Self.layerKind(of: place),
                MapLayerStyle.pinCaptionKey: Self.caption(of: place)
            ]
            shapes.append(pin)
        }
        placesSource.shape = MLNShapeCollectionFeature(shapes: shapes)
    }

    static func layerKind(of place: WatchedPlace) -> String {
        switch place.kind {
        case .currentLocation: MapLayerStyle.currentLocationKind
        case .home: MapLayerStyle.homeKind
        case .custom: MapLayerStyle.customKind
        }
    }

    /// «Дім · Ірпінь» for the home; a custom place by its name.
    static func caption(of place: WatchedPlace) -> String {
        guard place.kind == .home else { return place.title }
        return place.address?.locality.map { "\(place.title) · \($0)" } ?? place.title
    }

    /// The blue dot, the flight to the user and the places' circles, from the view's latest values.
    func updatePlaces(
        from view: AirRaidMapView,
        flyRequested: Bool
    ) {
        updateUserLocation(from: view, flyRequested: flyRequested)
        if view.places != places {
            places = view.places
            applyPlaces()
        }
    }

    /// Shows or hides the blue dot, and flies the camera when asked.
    func updateUserLocation(
        from view: AirRaidMapView,
        flyRequested: Bool
    ) {
        if mapView?.showsUserLocation != view.showsUserLocation {
            mapView?.showsUserLocation = view.showsUserLocation
        }
        if flyRequested, let request = view.flyRequest {
            fly(to: request.coordinate)
        }
    }}
