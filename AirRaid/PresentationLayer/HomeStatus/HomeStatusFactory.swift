//
//  HomeStatusFactory.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import HomeStatusKit

/// Turns the watched place and the live situation into what the widgets and the Live Activity show, formatted the way
/// the map's home sheet and banners read.
enum HomeStatusFactory {

    /// The place's status at the moment.
    ///
    /// - Parameters:
    ///   - place: The home pin, or the user's location while there is no home.
    ///   - situation: The live alerts and threats.
    ///   - regions: Every oblast outline, to find the place's oblast and draw it.
    ///   - districts: Every raion outline, to find the place's raion and fill the mini-map.
    ///   - now: The moment the forecast distances are for.
    static func make(
        place: WatchedPlace,
        situation: AirSituation,
        regions: [RegionBoundary],
        districts: [DistrictBoundary],
        now: Date
    ) -> HomeStatus {
        let region = regions.first { $0.contains(place.coordinate) }
        let district = districts.first { district in
            district.key.regionID == region?.id && district.polygons.contains { $0.contains(place.coordinate) }
        }
        let alert = situation.airRaidAlertSummary(regionID: region?.id, district: district?.key)
        let nearest = nearestThreat(to: place, among: situation.threats, now: now)
        return HomeStatus(
            placeKind: StatusPlaceKind(place.kind),
            placeName: place.address?.locality ?? place.kind.title,
            regionName: region?.name,
            alert: alert.map { HomeAlert(level: HomeAlertLevel($0.level), startedAt: $0.startedAt) },
            nearestThreat: nearest,
            closestThreat: nearest == nil ? closestThreat(to: place, among: situation.threats, now: now) : nil,
            radiusKm: place.radiusKm,
            miniMap: region.flatMap { region in
                MiniMapFactory.make(
                    region: region,
                    regions: regions,
                    districts: districts.filter { $0.key.regionID == region.id },
                    coverage: situation.airRaidCoverage,
                    home: place.coordinate
                )
            }
        )
    }
}

// MARK: - Private methods

private extension HomeStatusFactory {

    /// The nearest threat inside the place's radius by the same rule that turns its pin red on the map
    /// (``Threat/isNear(_:)``); the distance and the arrival are the forecast at `now`.
    static func nearestThreat(
        to place: WatchedPlace,
        among threats: [Threat],
        now: Date
    ) -> NearThreat? {
        let inside = threats
            .filter { $0.isNear(place) }
            .map { threat in (threat, threat.nearProximity(to: place, at: now)) }
            .sorted { $0.0.nearDistanceKm($0.1, to: place) < $1.0.nearDistanceKm($1.1, to: place) }
        guard let (threat, proximity) = inside.first else { return nil }
        guard let proximity else {
            return NearThreat(heading: threat, otherCount: inside.count - 1)
        }
        return NearThreat(threat, proximity: proximity, place: place, otherCount: inside.count - 1, now: now)
    }

    /// The nearest threat with a known position within ``Constants/closestThreatMaxKm``, wherever the radius ends: the
    /// Dynamic Island shows it while the radius is clear. Never red — it is not near by the map's rule.
    static func closestThreat(
        to place: WatchedPlace,
        among threats: [Threat],
        now: Date
    ) -> NearThreat? {
        guard let (threat, proximity) = measured(threats, from: place, now: now).first,
              proximity.distanceKm <= Constants.closestThreatMaxKm
        else { return nil }
        return NearThreat(threat, proximity: proximity, place: place, otherCount: 0, now: now)
    }

    /// The threats that have a position to measure from, nearest first.
    static func measured(
        _ threats: [Threat],
        from place: WatchedPlace,
        now: Date
    ) -> [(Threat, ThreatProximity)] {
        threats
            .compactMap { threat in threat.proximity(to: place.coordinate, at: now).map { (threat, $0) } }
            .sorted { $0.1.distanceKm < $1.1.distanceKm }
    }
}

// MARK: - NearThreat

private extension NearThreat {

    init(
        _ threat: Threat,
        proximity: ThreatProximity,
        place: WatchedPlace,
        otherCount: Int,
        now: Date
    ) {
        self.init(
            id: threat.id,
            title: threat.countedName,
            shortTitle: threat.shortName,
            iconName: ThreatIcon(threat).name,
            distanceText: "\(DisplayTime.distance(proximity)) \(place.fromText)",
            shortDistanceText: proximity.isWithinUncertainty
                ? "±\(Int(proximity.uncertaintyKm.rounded())) км"
                : DisplayTime.distance(proximity.distanceKm),
            arrivalAt: proximity.timeToArrival.map { now.addingTimeInterval($0) },
            otherCount: otherCount
        )
    }
}

private extension NearThreat {

    /// Only the target is known: "heading for <target>" in place of a distance, and no arrival.
    init(
        heading threat: Threat,
        otherCount: Int
    ) {
        let headingText = threat.headingText ?? ""
        self.init(
            id: threat.id,
            title: threat.countedName,
            shortTitle: threat.shortName,
            iconName: ThreatIcon(threat).name,
            distanceText: headingText,
            shortDistanceText: threat.target.map { "→ \($0.name)" } ?? "",
            arrivalAt: nil,
            otherCount: otherCount
        )
    }
}

// MARK: - StatusPlaceKind

private extension StatusPlaceKind {

    init(_ kind: WatchedPlaceKind) {
        switch kind {
        // Custom places never reach the widgets; one that did would read as a home.
        case .home, .custom: self = .home
        case .currentLocation: self = .currentLocation
        }
    }
}

// MARK: - HomeAlertLevel

private extension HomeAlertLevel {

    init(_ level: RegionAlertLevel) {
        switch level {
        case .yellow: self = .yellow
        case .red: self = .red
        }
    }
}

// MARK: - Constants

private enum Constants {
    /// Farther than this a threat says nothing about the place: a missile over Kharkiv is not news in Lviv.
    static let closestThreatMaxKm: Double = 100
}
