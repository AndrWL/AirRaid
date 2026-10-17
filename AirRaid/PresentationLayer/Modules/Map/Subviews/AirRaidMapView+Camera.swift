//
//  AirRaidMapView+Camera.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 16.10.2026.
//

import MapLibre

// MARK: - Camera

extension AirRaidMapView.Coordinator {

    /// Centres on the point, zooming in to about a raion unless the map is already closer. While a details sheet
    /// covers the lower half, the point goes to the middle of the half above it.
    func fly(to location: GeoCoordinate) {
        guard let mapView else { return }
        guard isStyleLoaded else {
            pendingFlyLocation = location
            return
        }
        keepsFit = false
        let zoomLevel = max(mapView.zoomLevel, MapLayerStyle.userZoomLevel)
        mapView.setCenter(
            CLLocationCoordinate2D(center(showing: location, atZoomLevel: zoomLevel, in: mapView)),
            zoomLevel: zoomLevel,
            animated: true
        )
    }

    /// Starts the camera on the point without the flight: the map has only just appeared.
    func showAtLaunch(_ location: GeoCoordinate) {
        guard let mapView else { return }
        keepsFit = false
        mapView.setCenter(CLLocationCoordinate2D(location), zoomLevel: MapLayerStyle.userZoomLevel, animated: false)
    }

    /// Brings a just-selected threat closer: zooms in to about an oblast and centres it above its sheet. Leaves the
    /// camera alone when the map is already that close and the pin is in view above the sheet.
    func revealThreat(at location: GeoCoordinate?) {
        guard let location, let mapView, isDetailsSheetShown else { return }
        let point = mapView.convert(CLLocationCoordinate2D(location), toPointTo: mapView)
        let visibleArea = CGRect(
            x: 0,
            y: mapView.safeAreaInsets.top,
            width: mapView.bounds.width,
            height: mapView.bounds.height * MapLayerStyle.sheetFreeShare - mapView.safeAreaInsets.top
        ).insetBy(dx: MapLayerStyle.revealMargin, dy: MapLayerStyle.revealMargin)
        guard mapView.zoomLevel < MapLayerStyle.selectionZoomLevel || !visibleArea.contains(point) else { return }
        keepsFit = false
        let zoomLevel = max(mapView.zoomLevel, MapLayerStyle.selectionZoomLevel)
        mapView.setCenter(
            CLLocationCoordinate2D(center(showing: location, atZoomLevel: zoomLevel, in: mapView)),
            zoomLevel: zoomLevel,
            animated: true
        )
    }
}

// MARK: - Private methods

private extension AirRaidMapView.Coordinator {

    /// The camera centre that puts `location` in the middle of the map, or of the part above a details sheet.
    func center(
        showing location: GeoCoordinate,
        atZoomLevel zoomLevel: Double,
        in mapView: MLNMapView
    ) -> GeoCoordinate {
        guard isDetailsSheetShown else { return location }
        // From the map's middle to the middle of its upper part, in points.
        let offset = mapView.bounds.height * (1 - MapLayerStyle.sheetFreeShare) / 2
        let metersPerPoint = mapView.metersPerPoint(atLatitude: location.latitude) * pow(2, mapView.zoomLevel - zoomLevel)
        return location.moved(bearing: 180, distanceKm: offset * metersPerPoint / 1_000)
    }
}
