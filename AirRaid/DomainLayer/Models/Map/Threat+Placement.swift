//
//  Threat+Placement.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Where to put a threat's pin, taking the alerts into account.
///
/// A report that names only the oblast says nothing about where in it the threat is, and the backend's
/// ``ThreatArea/center`` is the regional center — often a city with no alert at all. When only some raions of the
/// oblast are alerted, the threat is in one of them, so the pin goes there instead.
nonisolated extension Threat {

    /// ``markerCoordinate``, except that an area-only report in a partly alerted oblast is put inside the alerted
    /// raion nearest to the oblast's center — a whole-raion alert before a hromada one.
    ///
    /// Keeps the oblast's center when the whole oblast is alerted or none of its raions is.
    func markerCoordinate(
        coverage: AirRaidCoverage,
        districts: [DistrictBoundary]
    ) -> GeoCoordinate? {
        guard position == nil, target == nil, !isCountryWide, coverage.regions[area.regionID] == nil else {
            return markerCoordinate
        }

        let center = area.center
        let alerted = districts.compactMap { district -> (extent: RegionAlertExtent, point: GeoCoordinate)? in
            guard
                district.key.regionID == area.regionID,
                let extent = coverage.districts[district.key]?.extent,
                let point = district.interiorPoint
            else { return nil }
            return (extent, point)
        }
        let nearest = alerted.min { lhs, rhs in
            if lhs.extent != rhs.extent {
                return lhs.extent > rhs.extent
            }
            return lhs.point.squaredDistance(to: center) < rhs.point.squaredDistance(to: center)
        }
        return nearest?.point ?? center
    }
}

// MARK: - DistrictBoundary

nonisolated private extension DistrictBoundary {

    /// A point inside the raion's largest polygon: its centroid when that falls inside, otherwise the middle of the
    /// widest stretch of the polygon along the centroid's latitude (a crescent-shaped raion has its centroid outside).
    var interiorPoint: GeoCoordinate? {
        guard let ring = polygons.map(\.exterior).max(by: { abs($0.signedArea) < abs($1.signedArea) }),
              ring.count >= 3
        else { return nil }

        let centroid = ring.centroid
        if ring.encloses(centroid) {
            return centroid
        }
        return ring.widestCrossing(atLatitude: centroid.latitude) ?? centroid
    }
}

// MARK: - GeoCoordinate

nonisolated private extension GeoCoordinate {

    /// For comparing distances only: an equirectangular approximation, fine within one oblast.
    func squaredDistance(to other: GeoCoordinate) -> Double {
        let deltaLat = latitude - other.latitude
        let deltaLon = (longitude - other.longitude) * cos(latitude * .pi / 180)
        return deltaLat * deltaLat + deltaLon * deltaLon
    }
}
