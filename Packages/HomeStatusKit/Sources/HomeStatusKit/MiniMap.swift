//
//  MiniMap.swift
//  HomeStatusKit
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// The home's oblast drawn small: its outline, its raions filled by their alerts, and the home pin.
///
/// Already projected by the app: points are fractions of the map's frame, `x` from the left and `y` from the top, so
/// the widget only scales them into its own frame with ``aspectRatio``.
public struct MiniMap: Codable, Hashable, Sendable {

    /// Width over height of the projected oblast.
    public let aspectRatio: Double

    /// The oblast first, then its raions; drawn in this order.
    public let areas: [MiniMapArea]

    /// The home pin.
    public let home: MiniMapPoint

    public init(
        aspectRatio: Double,
        areas: [MiniMapArea],
        home: MiniMapPoint
    ) {
        self.aspectRatio = aspectRatio
        self.areas = areas
        self.home = home
    }
}

// MARK: - MiniMapArea

/// One outline on the mini-map: the oblast or a raion.
public struct MiniMapArea: Codable, Hashable, Sendable {

    /// Outer rings and holes alike; drawn with the even-odd rule, so Kyiv stays a hole in Kyiv Oblast.
    public let rings: [[MiniMapPoint]]

    public let fill: MiniMapFill

    public init(
        rings: [[MiniMapPoint]],
        fill: MiniMapFill
    ) {
        self.rings = rings
        self.fill = fill
    }
}

/// How an area is filled, the same way the app's map fills it.
public enum MiniMapFill: String, Codable, Hashable, Sendable {

    /// No alert.
    case none

    /// The whole area is under a yellow alert.
    case yellow

    /// The whole area is under a red alert.
    case red

    /// Only a hromada inside the raion is under a yellow alert: a pale fill.
    case yellowPartial

    /// Only a hromada inside the raion is under a red alert: a pale fill.
    case redPartial
}

// MARK: - MiniMapPoint

/// A point as fractions of the mini-map's frame. Encoded as `[x, y]`: an oblast has thousands of them.
public struct MiniMapPoint: Codable, Hashable, Sendable {

    public let x: Double

    public let y: Double

    public init(
        x: Double,
        y: Double
    ) {
        self.x = x
        self.y = y
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        x = try container.decode(Double.self)
        y = try container.decode(Double.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}
