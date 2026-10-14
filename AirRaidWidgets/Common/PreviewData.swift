//
//  PreviewData.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import HomeStatusKit

/// Samples for the previews and the widget gallery; `nonisolated` for the timeline provider.
nonisolated extension HomeStatusSnapshot {

    /// A red alert for an hour with a Shahed 14 km from home, four minutes out.
    static var previewAlert: HomeStatusSnapshot {
        HomeStatusSnapshot(
            updatedAt: .now,
            home: HomeStatus(
                placeKind: .home,
                placeName: "Ірпінь",
                regionName: "Київська область",
                alert: HomeAlert(level: .red, startedAt: .now.addingTimeInterval(-3_725)),
                nearestThreat: .preview,
                radiusKm: 25,
                miniMap: .preview(alerted: true)
            )
        )
    }

    static var previewCalm: HomeStatusSnapshot {
        HomeStatusSnapshot(
            updatedAt: .now,
            home: HomeStatus(
                placeKind: .home,
                placeName: "Ірпінь",
                regionName: "Київська область",
                alert: nil,
                nearestThreat: nil,
                radiusKm: 25,
                miniMap: .preview(alerted: false)
            )
        )
    }
}

nonisolated extension HomeAlertActivityState {

    static var previewThreat: HomeAlertActivityState {
        HomeAlertActivityState(alert: previewAlert, nearestThreat: .preview, radiusKm: 25)
    }

    /// Nothing in the radius, a Shahed 42 km away.
    static var previewOutside: HomeAlertActivityState {
        HomeAlertActivityState(alert: previewAlert, nearestThreat: nil, closestThreat: .previewOutside, radiusKm: 10)
    }

    static var previewClear: HomeAlertActivityState {
        HomeAlertActivityState(alert: previewAlert, nearestThreat: nil, radiusKm: 25)
    }

    static var previewEnded: HomeAlertActivityState {
        HomeAlertActivityState(alert: nil, nearestThreat: nil, radiusKm: 25, isAllClear: true)
    }

    /// No alert at the place, a Shahed inside its radius.
    static var previewThreatOnly: HomeAlertActivityState {
        HomeAlertActivityState(alert: nil, nearestThreat: .preview, radiusKm: 25)
    }

    private static var previewAlert: HomeAlert {
        HomeAlert(level: .red, startedAt: .now.addingTimeInterval(-3_725))
    }
}

nonisolated extension NearThreat {

    static var preview: NearThreat {
        NearThreat(
            id: "preview",
            title: "Шахед ×3",
            shortTitle: "Шахед",
            iconName: "threat-shahed",
            distanceText: "14 км від дому",
            shortDistanceText: "14 км",
            arrivalAt: .now.addingTimeInterval(252),
            otherCount: 1
        )
    }

    static var previewOutside: NearThreat {
        NearThreat(
            id: "preview-outside",
            title: "Шахед",
            shortTitle: "Шахед",
            iconName: "threat-shahed",
            distanceText: "42 км від дому",
            shortDistanceText: "42 км",
            arrivalAt: nil,
            otherCount: 0
        )
    }
}

nonisolated extension MiniMap {

    /// A rough oblast split into two raions, one of them alerted.
    static func preview(alerted: Bool) -> MiniMap {
        let outline = [(0.1, 0.0), (0.7, 0.05), (1.0, 0.4), (0.85, 1.0), (0.3, 0.9), (0.0, 0.5)]
        let west = [(0.1, 0.0), (0.5, 0.03), (0.5, 0.95), (0.3, 0.9), (0.0, 0.5)]
        let east = [(0.5, 0.03), (0.7, 0.05), (1.0, 0.4), (0.85, 1.0), (0.5, 0.95)]
        func ring(_ points: [(Double, Double)]) -> [MiniMapPoint] {
            points.map { MiniMapPoint(x: $0.0, y: $0.1) }
        }
        return MiniMap(
            aspectRatio: 1.1,
            areas: [
                MiniMapArea(rings: [ring(outline)], fill: .none),
                MiniMapArea(rings: [ring(west)], fill: alerted ? .red : .none),
                MiniMapArea(rings: [ring(east)], fill: alerted ? .yellowPartial : .none)
            ],
            home: MiniMapPoint(x: 0.35, y: 0.45)
        )
    }
}
