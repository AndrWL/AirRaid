//
//  MiniMapFactory.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import HomeStatusKit

/// Projects the home's oblast into a widget-sized ``MiniMap``, filled the way the app's map fills it.
///
/// An equirectangular projection around the oblast's middle latitude: within one oblast it looks the same as the
/// app's Web Mercator map. Rings are thinned to ``Constants/maxPointsPerRing`` points, since a widget is a few hundred
/// points wide and every point travels through the App Group file.
enum MiniMapFactory {

    /// The mini-map of `region`, or `nil` for a region without outlines.
    ///
    /// - Parameters:
    ///   - region: The home's oblast.
    ///   - regions: Every oblast, for the cities inside the oblast's holes (Kyiv in Kyiv Oblast).
    ///   - districts: The oblast's raions.
    ///   - coverage: Where the air raid alerts are.
    ///   - home: The home pin.
    static func make(
        region: RegionBoundary,
        regions: [RegionBoundary],
        districts: [DistrictBoundary],
        coverage: AirRaidCoverage,
        home: GeoCoordinate
    ) -> MiniMap? {
        guard let box = region.boundingBox else { return nil }
        let projection = Projection(box: box)
        guard projection.width > 0, projection.height > 0 else { return nil }

        let regionLevel = coverage.regions[region.id]
        var areas = [MiniMapArea(rings: rings(of: region.polygons, projection), fill: MiniMapFill(level: regionLevel))]
        // Raions only matter when the oblast is not alerted as a whole; their outlines are drawn either way.
        areas += districts.map { district in
            let districtCoverage = regionLevel == nil ? coverage.districts[district.key] : nil
            return MiniMapArea(rings: rings(of: district.polygons, projection), fill: MiniMapFill(coverage: districtCoverage))
        }
        areas += enclaves(of: region, among: regions).map { enclave in
            MiniMapArea(rings: rings(of: enclave.polygons, projection), fill: MiniMapFill(level: coverage.regions[enclave.id]))
        }
        return MiniMap(aspectRatio: projection.width / projection.height, areas: areas, home: projection.point(home))
    }
}

// MARK: - Private methods

private extension MiniMapFactory {

    static func rings(
        of polygons: [GeoPolygon],
        _ projection: Projection
    ) -> [[MiniMapPoint]] {
        polygons
            .flatMap { [$0.exterior] + $0.holes }
            .map { ring in thinned(ring).map(projection.point) }
    }

    /// Every n-th point, keeping the ring's shape at widget scale.
    static func thinned(_ ring: [GeoCoordinate]) -> [GeoCoordinate] {
        let step = Int((Double(ring.count) / Double(Constants.maxPointsPerRing)).rounded(.up))
        guard step > 1 else { return ring }
        return stride(from: 0, to: ring.count, by: step).map { ring[$0] }
    }

    /// Regions that sit in the oblast's holes — Kyiv in Kyiv Oblast — so the mini-map has no blank spot there.
    static func enclaves(
        of region: RegionBoundary,
        among regions: [RegionBoundary]
    ) -> [RegionBoundary] {
        let holes = region.polygons.flatMap(\.holes)
        guard !holes.isEmpty else { return [] }
        return regions.filter { other in
            guard other.id != region.id, let centroid = other.polygons.first?.exterior.centroid else { return false }
            return holes.contains { $0.encloses(centroid) }
        }
    }
}

// MARK: - Projection

/// Degrees to fractions of the mini-map's frame.
nonisolated private struct Projection {

    let box: GeoBoundingBox

    /// Shrinks longitudes to their length at the oblast's middle latitude.
    let longitudeScale: Double

    init(box: GeoBoundingBox) {
        self.box = box
        longitudeScale = cos((box.southWest.latitude + box.northEast.latitude) / 2 * .pi / 180)
    }

    var width: Double {
        (box.northEast.longitude - box.southWest.longitude) * longitudeScale
    }

    var height: Double {
        box.northEast.latitude - box.southWest.latitude
    }

    /// `y` grows southward, the way the widget draws.
    func point(_ coordinate: GeoCoordinate) -> MiniMapPoint {
        MiniMapPoint(
            x: Self.rounded((coordinate.longitude - box.southWest.longitude) * longitudeScale / width),
            y: Self.rounded((box.northEast.latitude - coordinate.latitude) / height)
        )
    }

    /// Four decimals: a tenth of a point on the largest widget, and a quarter of the file.
    static func rounded(_ value: Double) -> Double {
        (value * Constants.precision).rounded() / Constants.precision
    }
}

// MARK: - MiniMapFill

private extension MiniMapFill {

    init(level: RegionAlertLevel?) {
        switch level {
        case .red: self = .red
        case .yellow: self = .yellow
        case nil: self = .none
        }
    }

    init(coverage: RegionAlertCoverage?) {
        guard let coverage else {
            self = .none
            return
        }
        switch (coverage.level, coverage.extent) {
        case (.red, .whole): self = .red
        case (.red, .partial): self = .redPartial
        case (.yellow, .whole): self = .yellow
        case (.yellow, .partial): self = .yellowPartial
        }
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    static let maxPointsPerRing = 160
    static let precision: Double = 10_000
}
