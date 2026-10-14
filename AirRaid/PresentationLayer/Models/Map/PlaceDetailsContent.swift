//
//  PlaceDetailsContent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// What a saved place's sheet shows, formatted for one moment: where the place is, whether there is an air raid alert
/// right there, and the threats inside its radius, nearest first.
struct PlaceDetailsContent {

    // MARK: - Variables

    /// «Дім», «Робота».
    let title: String

    let kind: WatchedPlaceKind

    /// «вулиця Соборна, 12»; `nil` until the address is known.
    let street: String?

    /// «Ірпінь · Київська область»; `nil` until either is known.
    let placeLine: String?

    /// The air raid alert at the place's own point: its oblast, or the raion it is in.
    let alertLevel: RegionAlertLevel?

    let radiusKm: Double

    /// Threats whose reported position is inside the radius, nearest first.
    let threats: [ThreatRow]

    init(
        place savedPlace: SavedPlace,
        regionName: String?,
        alertLevel: RegionAlertLevel?,
        threats: [Threat],
        now: Date
    ) {
        let place = WatchedPlace(savedPlace)
        title = place.title
        kind = place.kind
        street = place.address?.street
        // A named custom place shows its locality under the name; one named by its locality does not repeat it.
        // Nor the city that is its own region: «Київ», not «Київ · Київ».
        let locality = place.address?.locality == title ? nil : place.address?.locality
        var parts = [locality, regionName].compactMap { $0 }
        if parts.count == 2, parts[0] == parts[1] {
            parts.removeLast()
        }
        placeLine = parts.isEmpty ? nil : parts.joined(separator: " · ")
        self.alertLevel = alertLevel
        radiusKm = place.radiusKm

        self.threats = threats
            .filter { $0.isNear(place) }
            .compactMap { threat in threat.proximity(to: place.coordinate, at: now).map { (threat, $0) } }
            .sorted { $0.1.distanceKm < $1.1.distanceKm }
            .map { ThreatRow(threat: $0.0, proximity: $0.1, place: place) }
    }

    /// «Повітряна тривога», «Тривоги немає».
    var alertTitle: String {
        alertLevel == nil ? "Тривоги немає" : "Повітряна тривога"
    }
}

// MARK: - ThreatRow

extension PlaceDetailsContent {

    /// One threat inside the place's radius.
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
            proximity: ThreatProximity,
            place: WatchedPlace
        ) {
            id = threat.id
            title = threat.countedName
            iconName = ThreatIcon(threat).name
            let distance = "\(DisplayTime.distance(proximity)) \(place.fromText)"
            detail = proximity.timeToArrival.map { "\(distance) · \(DisplayTime.estimate($0))" } ?? distance
        }
    }
}
