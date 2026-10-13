//
//  AirRaidMapView+Forecast.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import MapLibre

/// Where reliable threats probably are now: a faint copy of the pin at the forecast position, joined to the real pin
/// by a dotted line. The real pin never moves off the last confirmed position, so a fact and a guess always look
/// different. Threats whose forecast is not reliable (``Threat/hasReliableForecast``) get no ghost at all.
extension AirRaidMapView.Coordinator {

    func installForecastLayers(in style: MLNStyle) {
        let source = MLNShapeSource(identifier: MapLayerStyle.forecastSourceID, shape: nil)
        style.addSource(source)
        forecastSource = source

        let link = MLNLineStyleLayer(identifier: MapLayerStyle.forecastLinkLayerID, source: source)
        link.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.forecastPartKey, MapLayerStyle.forecastLinkPart)
        link.lineColor = NSExpression(forConstantValue: MapLayerStyle.trackColor)
        link.lineOpacity = NSExpression(forConstantValue: MapLayerStyle.forecastLinkOpacity)
        link.lineWidth = NSExpression(forConstantValue: MapLayerStyle.forecastLinkWidth)
        link.lineDashPattern = NSExpression(forConstantValue: MapLayerStyle.forecastLinkDashPattern)

        let ghost = MLNSymbolStyleLayer(identifier: MapLayerStyle.forecastGhostLayerID, source: source)
        ghost.predicate = NSPredicate(format: "%K == %@", MapLayerStyle.forecastPartKey, MapLayerStyle.forecastGhostPart)
        ghost.iconImageName = NSExpression(forKeyPath: MapLayerStyle.iconNameKey)
        ghost.iconRotation = NSExpression(forKeyPath: MapLayerStyle.headingKey)
        ghost.iconRotationAlignment = NSExpression(forConstantValue: MapLayerStyle.mapAlignment)
        ghost.iconScale = NSExpression(forConstantValue: MapLayerStyle.threatIconScale)
        ghost.iconOpacity = NSExpression(forConstantValue: MapLayerStyle.forecastGhostOpacity)
        ghost.iconAllowsOverlap = NSExpression(forConstantValue: true)
        ghost.iconIgnoresPlacement = NSExpression(forConstantValue: true)

        // Under the real pins, so a ghost never covers the confirmed position it came from.
        if let pins = style.layer(withIdentifier: MapLayerStyle.threatLayerID) {
            style.insertLayer(link, below: pins)
            style.insertLayer(ghost, below: pins)
        } else {
            [link, ghost].forEach(style.addLayer)
        }
    }

    /// Rebuilds the ghosts for the moment; called when the threats change and on a timer, since a ghost moves on
    /// between reports.
    func applyForecast(
        threats: [Threat],
        at date: Date
    ) {
        guard let forecastSource else { return }
        let shapes = threats.flatMap { threat -> [MLNShape] in
            guard
                let position = threat.position,
                let forecast = threat.reliableForecastCoordinate(at: date)
            else { return [] }

            var coordinates = [CLLocationCoordinate2D(position.coordinate), CLLocationCoordinate2D(forecast)]
            let link = MLNPolylineFeature(coordinates: &coordinates, count: UInt(coordinates.count))
            link.attributes = [MapLayerStyle.forecastPartKey: MapLayerStyle.forecastLinkPart]

            let icon = ThreatIcon(threat)
            let ghost = MLNPointFeature()
            ghost.coordinate = CLLocationCoordinate2D(forecast)
            ghost.attributes = [
                MapLayerStyle.forecastPartKey: MapLayerStyle.forecastGhostPart,
                MapLayerStyle.iconNameKey: icon.name,
                MapLayerStyle.headingKey: icon.rotatesWithHeading ? threat.course ?? 0 : 0
            ]
            return [link, ghost]
        }
        forecastSource.shape = MLNShapeCollectionFeature(shapes: shapes)
    }
}
