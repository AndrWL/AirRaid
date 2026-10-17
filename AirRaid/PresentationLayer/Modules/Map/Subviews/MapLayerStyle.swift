//
//  MapLayerStyle.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import MapLibre

/// Source and layer ids, feature attribute keys, colours and sizes of the map's own layers.
enum MapLayerStyle {
    /// Ukraine's bounding box; the camera fits it on load so the whole country is visible on any screen.
    static let ukraineBounds = MLNCoordinateBounds(
        sw: CLLocationCoordinate2D(latitude: 44.3, longitude: 22.1),
        ne: CLLocationCoordinate2D(latitude: 52.4, longitude: 40.3)
    )
    /// Wider on the left for Uzhhorod's label, which is centred on the city at the country's western edge; the width
    /// limits the fit on a phone.
    static let ukraineEdgePadding = UIEdgeInsets(top: 60, left: 40, bottom: 8, right: 8)
    /// Room for the chips and the focus pill above, and the tab bar below.
    static let focusEdgePadding = UIEdgeInsets(top: 150, left: 24, bottom: 120, right: 24)
    /// How far past the focused region's box the camera centre may be panned, as a share of the box.
    static let focusPanMargin: Double = 0.25
    /// About a raion across on a phone: close enough to see what is around the user.
    static let userZoomLevel: Double = 8.5
    /// A little closer than the whole country, about an oblast across: where a selected threat is and what is around it.
    static let selectionZoomLevel: Double = 6
    /// The share of the map's height above a details sheet at its half height.
    static let sheetFreeShare: CGFloat = 0.5
    /// How far inside the area above the sheet a selected pin must be to count as visible.
    static let revealMargin: CGFloat = 24
    /// Beside MapLibre's logo, which takes the bottom-left corner at its default margins.
    static let attributionButtonMargins = CGPoint(x: 100, y: 8)

    static let regionSourceID = "regions"
    static let districtSourceID = "districts"
    static let citySourceID = "cities"
    static let threatSourceID = "threats"
    static let selectedTrackSourceID = "selected-track"
    static let forecastSourceID = "forecast"
    static let forecastLinkLayerID = "forecast-link"
    static let forecastGhostLayerID = "forecast-ghost"
    static let forecastPartKey = "forecastPart"
    static let forecastLinkPart = "link"
    static let forecastGhostPart = "ghost"
    static let territoryFillLayerID = "regions-territory-fill"
    static let regionAlertFillLayerID = "regions-alert-fill"
    static let districtAlertFillLayerID = "districts-alert-fill"
    static let districtOutlineLayerID = "districts-outline"
    static let outlineLayerID = "regions-outline"
    static let selectedRegionOutlineLayerID = "regions-selected-outline"
    static let focusDimLayerID = "regions-focus-dim"
    static let placesSourceID = "places"
    static let placeRadiusFillLayerID = "places-radius-fill"
    static let placeRadiusOutlineLayerID = "places-radius-outline"
    static let homeRadiusOutlineLayerID = "places-home-radius-outline"
    static let customRadiusOutlineLayerID = "places-custom-radius-outline"
    static let placePinLayerID = "places-pins"
    static let placePartKey = "placePart"
    static let placeKindKey = "placeKind"
    static let currentLocationKind = "currentLocation"
    static let homeKind = "home"
    static let customKind = "custom"
    static let radiusPart = "radius"
    static let pinPart = "pin"
    static let homeIconName = "home-pin"
    static let savedPlaceIconName = "saved-place-pin"
    static let pinCaptionKey = "pinCaption"
    /// Below the pin, in ems: the pin is a 32 pt disc.
    static let pinCaptionOffset = CGVector(dx: 0, dy: 1.6)
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
    static let outsideFocusKey = "outsideFocus"
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
    static let outsideFocusOpacity: Double = 0.25
    static let focusDimColor = UIColor.mapDim
    static let focusDimOpacity: Double = 0.7
    /// The user's location is blue like the system's blue dot; the home is orange (#FF8000), so the two never read as one;
    /// the other places are violet, apart from both and from the alert colours.
    static let currentLocationColor = UIColor.mapPlace
    static let homeColor = UIColor.mapHome
    static let savedPlaceColor = UIColor.mapSavedPlace
    static let placeRadiusFillOpacity: Double = 0.1
    static let placeRadiusOutlineOpacity: Double = 1
    static let placeRadiusOutlineWidth: Double = 1.5

    /// A white house on an orange disc with a white rim, the way the blue dot marks the user.
    static let homeIcon = makePinIcon(systemName: "house.fill", color: .mapHome)

    /// A white pin on a violet disc: a custom place.
    static let savedPlaceIcon = makePinIcon(systemName: "mappin", color: .mapSavedPlace)

    /// A white symbol on a coloured disc with a white rim.
    ///
    /// Drawn into a bitmap rather than handed over as a palette symbol: MapLibre keeps only the symbol's shape and
    /// draws it black.
    static func makePinIcon(systemName: String, color: UIColor) -> UIImage {
        let size = CGSize(width: homeIconSize, height: homeIconSize)
        let traits = UITraitCollection(userInterfaceStyle: .dark)
        let disc = color.resolvedColor(with: traits)
        let rim = UIColor.mapTrack.resolvedColor(with: traits)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let bounds = CGRect(origin: .zero, size: size)
            rim.setFill()
            UIBezierPath(ovalIn: bounds).fill()
            disc.setFill()
            UIBezierPath(ovalIn: bounds.insetBy(dx: homeIconRim, dy: homeIconRim)).fill()
            let configuration = UIImage.SymbolConfiguration(pointSize: homeIconSize * 0.45, weight: .bold)
            if let symbol = UIImage(systemName: systemName, withConfiguration: configuration)?
                .withTintColor(rim, renderingMode: .alwaysOriginal) {
                symbol.draw(at: CGPoint(x: bounds.midX - symbol.size.width / 2, y: bounds.midY - symbol.size.height / 2))
            }
        }
    }
    static let homeIconSize: CGFloat = 32
    static let homeIconRim: CGFloat = 2.5
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
    /// Faint enough that the ghost never reads as a second threat.
    static let forecastGhostOpacity: Double = 0.35
    static let forecastLinkOpacity: Double = 0.4
    static let forecastLinkWidth: Double = 1.2
    static let forecastLinkDashPattern: [Double] = [1, 2]

    /// Half the side of the square a tap searches for pins: about a fingertip.
    static let tapRadius: CGFloat = 22
    static let cityHaloWidth: Double = 1.2
}
