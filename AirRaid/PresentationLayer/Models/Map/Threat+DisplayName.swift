//
//  Threat+DisplayName.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// User-facing names of threats, as agreed with the backend (`vydy_zagroz.xlsx`, 07.10.2026).
extension Threat {

    /// The type's name when known, otherwise the category's.
    var displayName: String {
        type?.displayName ?? kind.displayName
    }
}

// MARK: - ThreatType

extension ThreatType {

    var displayName: String {
        switch self {
        case .shahed: return "Шахед"
        case .jetDrone: return "Реактивний БпЛА"
        case .reconDrone: return "Розвідувальний БпЛА"
        case .drone: return "БпЛА"
        case .fpv: return "FPV-дрон"
        case .guidedAerialBomb: return "КАБ"
        case .cruiseMissile: return "Крилата ракета"
        case .highSpeedTarget: return "Швидкісна ціль"
        case .missile: return "Ракета"
        case .ballisticMissile: return "Балістика"
        case .aviation: return "Авіація"
        }
    }
}

// MARK: - ThreatKind

extension ThreatKind {

    /// Also the label of the category filter.
    var displayName: String {
        switch self {
        case .drone: return "БпЛА"
        case .fpv: return "FPV-дрон"
        case .guidedAerialBomb: return "КАБ"
        case .missile: return "Ракета"
        case .ballisticMissile: return "Балістика"
        case .aviation: return "Авіація"
        case .unknown: return "Ціль"
        }
    }
}
