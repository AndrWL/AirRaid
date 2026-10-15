//
//  FeedFilter.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

/// Whose bubbles the feed shows. Free.
enum FeedScope: CaseIterable, Hashable {

    /// The oblasts of the home and the current location, plus country-wide reports.
    case myPlaces

    case everywhere

    var title: String {
        switch self {
        case .myPlaces: "Мої місця"
        case .everywhere: "Вся Україна"
        }
    }
}

/// What kind of bubbles the feed shows. Anything but ``all`` is AirRaid Плюс.
enum FeedKindFilter: CaseIterable, Hashable {

    case all

    /// Cruise and ballistic missiles, high-speed targets.
    case missiles

    /// Every kind of drone.
    case drones

    case guidedBombs

    case aviation

    /// Official alerts only.
    case alerts

    var title: String {
        switch self {
        case .all: "Усе"
        case .missiles: "Ракети"
        case .drones: "БпЛА"
        case .guidedBombs: "КАБи"
        case .aviation: "Авіація"
        case .alerts: "Тривоги"
        }
    }

    func matches(_ item: FeedItem) -> Bool {
        switch (self, item.content) {
        case (.all, _):
            return true
        case (.alerts, .alert):
            return true
        case (.alerts, .threat), (_, .alert):
            return false
        case (.missiles, .threat(let threat)):
            return threat.kind == .missile || threat.kind == .ballisticMissile
        case (.drones, .threat(let threat)):
            return threat.kind == .drone || threat.kind == .fpv || threat.kind == .unknown
        case (.guidedBombs, .threat(let threat)):
            return threat.kind == .guidedAerialBomb
        case (.aviation, .threat(let threat)):
            return threat.kind == .aviation
        }
    }
}
