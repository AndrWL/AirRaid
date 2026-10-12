//
//  AirRaidMapView+Gestures.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import MapLibre

// MARK: - Tap

extension AirRaidMapView.Coordinator {

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

// MARK: - Long press

extension AirRaidMapView.Coordinator {

    /// Reports the pressed point once, when the press is recognized, not again while the finger moves.
    @objc
    func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, let mapView = recognizer.view as? MLNMapView else { return }
        let coordinate = mapView.convert(recognizer.location(in: mapView), toCoordinateFrom: mapView)
        onLongPress(GeoCoordinate(coordinate))
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

    /// Screen distance from the tap to a pin, to pick the nearest of overlapping pins.
    static func distance(
        from point: CGPoint,
        to feature: MLNFeature,
        in mapView: MLNMapView
    ) -> CGFloat {
        let featurePoint = mapView.convert(feature.coordinate, toPointTo: mapView)
        return hypot(featurePoint.x - point.x, featurePoint.y - point.y)
    }
}
