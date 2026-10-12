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

        let radiusOutline = MapFeatureFactory.makeOutline(
            identifier: MapLayerStyle.placeRadiusOutlineLayerID,
            source: source,
            color: MapLayerStyle.placeColor,
            opacity: MapLayerStyle.placeRadiusOutlineOpacity,
            width: MapLayerStyle.placeRadiusOutlineWidth
        )
        radiusOutline.predicate = radiusFill.predicate
        radiusOutline.lineDashPattern = NSExpression(forConstantValue: MapLayerStyle.placeRadiusDashPattern)

        let homePin = MLNSymbolStyleLayer(identifier: MapLayerStyle.homePinLayerID, source: source)
        homePin.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.placePartKey, MapLayerStyle.homePart)
        homePin.iconImageName = NSExpression(forConstantValue: MapLayerStyle.homeIconName)
        homePin.iconAllowsOverlap = NSExpression(forConstantValue: true)
        homePin.iconIgnoresPlacement = NSExpression(forConstantValue: true)

        [radiusFill, radiusOutline, homePin].forEach(style.addLayer)
    }

    func applyPlaces() {
        guard let placesSource else { return }
        var shapes: [MLNShape] = places.map { place in
            var ring = place.coordinate.circle(radiusKm: place.radiusKm).map(CLLocationCoordinate2D.init)
            let circle = MLNPolygonFeature(coordinates: &ring, count: UInt(ring.count))
            circle.attributes = [MapLayerStyle.placePartKey: MapLayerStyle.radiusPart]
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
        locateRequested: Bool
    ) {
        updateUserLocation(from: view, locateRequested: locateRequested)
        if view.places != places {
            places = view.places
            applyPlaces()
        }
    }

    /// Shows or hides the blue dot, and flies to the user when asked.
    func updateUserLocation(
        from view: AirRaidMapView,
        locateRequested: Bool
    ) {
        if mapView?.showsUserLocation != view.showsUserLocation {
            mapView?.showsUserLocation = view.showsUserLocation
        }
        if locateRequested, let location = view.userLocation {
            flyToUser(at: location)
        }
    }

    /// Centres on the user, zooming in to about a raion unless the map is already closer.
    func flyToUser(at location: GeoCoordinate) {
        guard let mapView else { return }
        mapView.setCenter(
            CLLocationCoordinate2D(location),
            zoomLevel: max(mapView.zoomLevel, MapLayerStyle.userZoomLevel),
            animated: true
        )
    }
}
