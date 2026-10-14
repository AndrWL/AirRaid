//
//  HomeDetailsContent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// What the home sheet shows, formatted for one moment: where the home is, whether there is an air raid alert right
/// there, and the threats inside its radius, nearest first.
struct HomeDetailsContent {

    // MARK: - Variables

    /// «вулиця Соборна, 12»; `nil` until the address is known.
    let street: String?

    /// «Ірпінь · Київська область»; `nil` until either is known.
    let placeLine: String?

    /// The air raid alert at the home's own point: its oblast, or the raion it is in.
    let alertLevel: RegionAlertLevel?

    let radiusKm: Double

    /// Threats whose reported position is inside the radius, nearest first.
    let threats: [ThreatRow]

    init(
        home: HomePlace,
        regionName: String?,
        alertLevel: RegionAlertLevel?,
        threats: [Threat],
        now: Date
    ) {
        street = home.address?.street
        let parts = [home.address?.locality, regionName].compactMap { $0 }
        placeLine = parts.isEmpty ? nil : parts.joined(separator: " · ")
        self.alertLevel = alertLevel
        radiusKm = home.radiusKm

        let place = WatchedPlace(kind: .home, coordinate: home.coordinate, radiusKm: home.radiusKm, address: home.address)
        self.threats = threats
            .filter { $0.isNear([place]) }
            .compactMap { threat in threat.proximity(to: home.coordinate, at: now).map { (threat, $0) } }
            .sorted { $0.1.distanceKm < $1.1.distanceKm }
            .map { ThreatRow(threat: $0.0, proximity: $0.1) }
    }

    /// «Повітряна тривога», «Тривоги немає».
    var alertTitle: String {
        alertLevel == nil ? "Тривоги немає" : "Повітряна тривога"
    }
}

// MARK: - ThreatRow

extension HomeDetailsContent {

    /// One threat inside the home's radius.
    struct ThreatRow: Identifiable {

        let id: String

        /// «Шахед ×3».
        let title: String

        /// The asset name of the threat's silhouette.
        let iconName: String

        /// «12 км від дому · ≈ 4 хв».
        let detail: String

        init(
            threat: Threat,
            proximity: ThreatProximity
        ) {
            id = threat.id
            title = threat.countedName
            iconName = ThreatIcon(threat).name
            let distance = "\(DisplayTime.distance(proximity)) \(WatchedPlaceKind.home.fromText)"
            detail = proximity.timeToArrival.map { "\(distance) · \(DisplayTime.estimate($0))" } ?? distance
        }
    }
}
