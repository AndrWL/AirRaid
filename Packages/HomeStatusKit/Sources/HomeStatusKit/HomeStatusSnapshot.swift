//
//  HomeStatusSnapshot.swift
//  HomeStatusKit
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// What the home screen and lock screen widgets show, as the app last saw it.
///
/// The app writes it to the App Group container on every change while it is open; the widget cannot reach the server,
/// so ``updatedAt`` tells it how old the picture is.
public struct HomeStatusSnapshot: Codable, Hashable, Sendable {

    /// The kind of the home status widget, for reloading its timelines from the app.
    public static let widgetKind = "HomeStatusWidget"

    /// When the app last had a live connection and wrote this.
    public let updatedAt: Date

    /// The watched place and its status — the home, else the user's location — or `nil` while there is neither.
    public let home: HomeStatus?

    public init(
        updatedAt: Date,
        home: HomeStatus?
    ) {
        self.updatedAt = updatedAt
        self.home = home
    }

    /// Whether the widget shows the same thing for both, ignoring when they were written.
    public func hasSameContent(as other: HomeStatusSnapshot?) -> Bool {
        home == other?.home
    }
}

// MARK: - HomeStatus

/// The status of the place the widgets follow: whether it is under an air raid alert and what flies inside its radius.
///
/// The home pin when there is one, otherwise the user's last known location.
public struct HomeStatus: Codable, Hashable, Sendable {

    /// Which place this is, for its symbol and wording ("from home", "from you").
    public let placeKind: StatusPlaceKind

    /// The locality, "Home" until the address is known, or "My location".
    public let placeName: String

    /// The oblast's name; `nil` when the home is outside every oblast outline.
    public let regionName: String?

    /// The air raid alert at the home's point, or `nil` when there is none.
    public let alert: HomeAlert?

    /// The nearest threat inside the home's radius, or `nil` when the radius is clear.
    public let nearestThreat: NearThreat?

    /// While the radius is clear, the nearest threat farther out (within the app's reach, 100 km), so a quiet
    /// radius does not hide a Shahed 30 km away; `nil` otherwise.
    public let closestThreat: NearThreat?

    /// The radius the home is watched in, in kilometres.
    public let radiusKm: Double

    /// The home's oblast with its alerts, or `nil` when the outlines could not be loaded.
    public let miniMap: MiniMap?

    public init(
        placeKind: StatusPlaceKind,
        placeName: String,
        regionName: String?,
        alert: HomeAlert?,
        nearestThreat: NearThreat?,
        closestThreat: NearThreat? = nil,
        radiusKm: Double,
        miniMap: MiniMap?
    ) {
        self.placeKind = placeKind
        self.placeName = placeName
        self.regionName = regionName
        self.alert = alert
        self.nearestThreat = nearestThreat
        self.closestThreat = closestThreat
        self.radiusKm = radiusKm
        self.miniMap = miniMap
    }
}

// MARK: - StatusPlaceKind

/// Which place the widgets and the Live Activity follow.
public enum StatusPlaceKind: String, Codable, Hashable, Sendable {

    /// The home pin.
    case home

    /// The user's location, while there is no home pin.
    case currentLocation
}

// MARK: - HomeAlert

/// An air raid alert at the home's point.
public struct HomeAlert: Codable, Hashable, Sendable {

    public let level: HomeAlertLevel

    /// When the earliest of the alerts covering the home was declared.
    public let startedAt: Date

    public init(
        level: HomeAlertLevel,
        startedAt: Date
    ) {
        self.level = level
        self.startedAt = startedAt
    }
}

/// The official danger level: yellow for drones, red for missiles and for an alert published without a level.
public enum HomeAlertLevel: String, Codable, Hashable, Sendable {
    case yellow
    case red
}

// MARK: - NearThreat

/// A threat inside the home's radius, formatted by the app the way the map's banner reads.
public struct NearThreat: Codable, Hashable, Sendable {

    /// Stays the same across updates of the same threat.
    public let id: String

    /// The threat's name with its count.
    public let title: String

    /// The type in a few letters, for the Dynamic Island's compact corner.
    public let shortTitle: String

    /// The asset name of the threat's silhouette, `threat-<type>`.
    public let iconName: String

    /// The distance from the place, or "within ±N km" for a rough position; as of ``HomeStatusSnapshot/updatedAt``.
    public let distanceText: String

    /// The distance, or "±N km", for the Dynamic Island's compact corner.
    public let shortDistanceText: String

    /// When the forecast puts the threat over the place, or `nil` unless it flies toward it.
    ///
    /// A moment rather than a duration, so it stays true however old the snapshot is: «≈ 10:42».
    public let arrivalAt: Date?

    /// How many more threats are inside the radius.
    public let otherCount: Int

    public init(
        id: String,
        title: String,
        shortTitle: String,
        iconName: String,
        distanceText: String,
        shortDistanceText: String,
        arrivalAt: Date?,
        otherCount: Int
    ) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.iconName = iconName
        self.distanceText = distanceText
        self.shortDistanceText = shortDistanceText
        self.arrivalAt = arrivalAt
        self.otherCount = otherCount
    }
}
