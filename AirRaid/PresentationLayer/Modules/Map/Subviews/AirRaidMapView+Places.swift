//
//  AirRaidMapView+Places.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import MapLibre

/// The user's watched places: a faint circle for each radius and a house pin on the home. The user's own position is
/// MapLibre's blue dot, so only its circle is drawn here.
extension AirRaidMapView.Coordinator {

    func installPlacesLayers(in style: MLNStyle) {
        let source = MLNShapeSource(identifier: MapLayerStyle.placesSourceID, shape: nil)
        style.addSource(source)
        placesSource = source
        style.setImage(MapLayerStyle.homeIcon, forName: MapLayerStyle.homeIconName)

        let radiusFill = MLNFillStyleLayer(identifier: MapLayerStyle.placeRadiusFillLayerID, source: source)
        radiusFill.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.placePartKey, MapLayerStyle.radiusPart)
        radiusFill.fillColor = NSExpression(forConstantValue: MapLayerStyle.placeColor)
        radiusFill.fillOpacity = NSExpression(forConstantValue: MapLayerStyle.placeRadiusFillOpacity)

        // A dark casing under the coloured line, the way labels get a halo: the circle crosses dark, yellow and red
        // fills, and a single blue line disappears on some of them.
        let radiusCasing = MapFeatureFactory.makeOutline(
            identifier: MapLayerStyle.placeRadiusCasingLayerID,
            source: source,
            color: MapLayerStyle.placeCasingColor,
            opacity: MapLayerStyle.placeRadiusCasingOpacity,
            width: MapLayerStyle.placeRadiusCasingWidth
        )
        radiusCasing.predicate = radiusFill.predicate

        // The user's own circle is solid, the home's dashed, so the two read apart where they overlap.
        let locationOutline = makeRadiusOutline(
            identifier: MapLayerStyle.placeRadiusOutlineLayerID,
            source: source,
            kind: MapLayerStyle.currentLocationKind
        )
        let homeOutline = makeRadiusOutline(
            identifier: MapLayerStyle.homeRadiusOutlineLayerID,
            source: source,
            kind: MapLayerStyle.homeKind
        )
        homeOutline.lineDashPattern = NSExpression(forConstantValue: MapLayerStyle.placeRadiusDashPattern)

        let homePin = MLNSymbolStyleLayer(identifier: MapLayerStyle.homePinLayerID, source: source)
        homePin.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.placePartKey, MapLayerStyle.homePart)
        homePin.iconImageName = NSExpression(forConstantValue: MapLayerStyle.homeIconName)
        homePin.iconAllowsOverlap = NSExpression(forConstantValue: true)
        homePin.iconIgnoresPlacement = NSExpression(forConstantValue: true)

        [radiusFill, radiusCasing, locationOutline, homeOutline, homePin].forEach(style.addLayer)
    }

    func makeRadiusOutline(
        identifier: String,
        source: MLNShapeSource,
        kind: String
    ) -> MLNLineStyleLayer {
        let outline = MapFeatureFactory.makeOutline(
            identifier: identifier,
            source: source,
            color: MapLayerStyle.placeColor,
            opacity: MapLayerStyle.placeRadiusOutlineOpacity,
            width: MapLayerStyle.placeRadiusOutlineWidth
        )
        outline.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            MapLayerStyle.placePartKey, MapLayerStyle.radiusPart,
            MapLayerStyle.placeKindKey, kind
        )
        return outline
    }

    func applyPlaces() {
        guard let placesSource else { return }
        var shapes: [MLNShape] = places.map { place in
            var ring = place.coordinate.circle(radiusKm: place.radiusKm).map(CLLocationCoordinate2D.init)
            let circle = MLNPolygonFeature(coordinates: &ring, count: UInt(ring.count))
            circle.attributes = [
                MapLayerStyle.placePartKey: MapLayerStyle.radiusPart,
                MapLayerStyle.placeKindKey: place.kind == .home ? MapLayerStyle.homeKind : MapLayerStyle.currentLocationKind
            ]
            return circle
        }
        if let home = places.first(where: { $0.kind == .home }) {
            let pin = MLNPointFeature()
            pin.coordinate = CLLocationCoordinate2D(home.coordinate)
            pin.attributes = [MapLayerStyle.placePartKey: MapLayerStyle.homePart]
            shapes.append(pin)
        }
        placesSource.shape = MLNShapeCollectionFeature(shapes: shapes)
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
    }

    /// Centres on the point, zooming in to about a raion unless the map is already closer.
    func fly(to location: GeoCoordinate) {
        guard let mapView else { return }
        mapView.setCenter(
            CLLocationCoordinate2D(location),
            zoomLevel: max(mapView.zoomLevel, MapLayerStyle.userZoomLevel),
            animated: true
        )
    }
}
