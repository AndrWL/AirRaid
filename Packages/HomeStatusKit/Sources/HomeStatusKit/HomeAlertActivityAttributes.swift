//
//  HomeAlertActivityAttributes.swift
//  HomeStatusKit
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

#if os(iOS)
import ActivityKit
import Foundation

/// The Live Activity shown on the lock screen and in the Dynamic Island while the home (or, without a home, the user's
/// location) is under an air raid alert.
///
/// The app starts it when the alert begins, updates it while it is open and ends it with the all clear when the alert is
/// lifted. It shows moments (since when, the forecast arrival) rather than timers, so it stays true between updates.
public struct HomeAlertActivityAttributes: ActivityAttributes {

    public typealias ContentState = HomeAlertActivityState

    /// The home, or the user's location while there is no home; fixed for the activity's lifetime.
    public let placeKind: StatusPlaceKind

    /// The locality, "Home" until the address is known, or "My location"; fixed for the activity's lifetime.
    public let placeName: String

    public init(
        placeKind: StatusPlaceKind,
        placeName: String
    ) {
        self.placeKind = placeKind
        self.placeName = placeName
    }
}
#endif

// MARK: - HomeAlertActivityState

/// What changes during a Live Activity: the alert, the nearest threat, the radius.
///
/// The activity runs for a fresh alert at the place, or for a threat inside its radius (also with no alert, or under an
/// alert that has lasted for days). Outside the `os(iOS)` block so the package's tests can build it on macOS.
public struct HomeAlertActivityState: Codable, Hashable, Sendable {

    /// The alert at the place, or `nil` when there is none — a threat in the radius started the activity, or the
    /// alert was lifted (``isAllClear``).
    public let alert: HomeAlert?

    /// The nearest threat inside the place's radius, or `nil` when the radius is clear.
    public let nearestThreat: NearThreat?

    /// While the radius is clear, the nearest threat farther out; see ``HomeStatus/closestThreat``.
    public let closestThreat: NearThreat?

    /// The radius the place is watched in, in kilometres.
    public let radiusKm: Double

    /// The activity's last state after the alert was lifted: the all clear.
    public let isAllClear: Bool

    public init(
        alert: HomeAlert?,
        nearestThreat: NearThreat?,
        closestThreat: NearThreat? = nil,
        radiusKm: Double,
        isAllClear: Bool = false
    ) {
        self.alert = alert
        self.nearestThreat = nearestThreat
        self.closestThreat = closestThreat
        self.radiusKm = radiusKm
        self.isAllClear = isAllClear
    }

    /// Tolerates content written before ``isAllClear`` existed: an activity outlives an app update.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alert = try container.decodeIfPresent(HomeAlert.self, forKey: .alert)
        nearestThreat = try container.decodeIfPresent(NearThreat.self, forKey: .nearestThreat)
        closestThreat = try container.decodeIfPresent(NearThreat.self, forKey: .closestThreat)
        radiusKm = try container.decode(Double.self, forKey: .radiusKm)
        isAllClear = try container.decodeIfPresent(Bool.self, forKey: .isAllClear) ?? (alert == nil)
    }
}
