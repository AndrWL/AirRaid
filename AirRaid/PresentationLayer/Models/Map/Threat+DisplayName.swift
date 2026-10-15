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

    /// «Шахед», «FPV», «Реакт.» — at most about six letters, for the Dynamic Island's compact corner.
    var shortName: String {
        type?.shortName ?? kind.shortName
    }

    /// «Шахед ×3» when the channels name more than one target, otherwise just ``displayName``.
    var countedName: String {
        guard let count, count > 1 else { return displayName }
        return "\(displayName) ×\(count)"
    }

    /// The caption under the map pin, from the most useful thing known: where it flies, else where it was spotted,
    /// else its region. Labelled the way the details sheet labels the same rows. `nil` for a country-wide report.
    var mapCaption: ThreatMapCaption? {
        if let target {
            return ThreatMapCaption(label: "курсом на", name: target.name)
        }
        if let position {
            return ThreatMapCaption(label: "зараз", name: position.name)
        }
        return isCountryWide ? nil : ThreatMapCaption(label: "область", name: area.name)
    }
}

// MARK: - ThreatMapCaption

/// Two lines under a pin: a small label («курсом на») over the place name («Кобеляки»).
///
/// The name stays in the nominative, as the backend sends it, so it reads as a value under a label rather than
/// as a phrase («курсом на Кобеляки» would need the accusative for «Звенигородка»).
struct ThreatMapCaption: Hashable {
    let label: String
    let name: String
}

// MARK: - ThreatType

extension ThreatType {

    var displayName: String {
        switch self {
        case .shahed: return "Шахед"
        case .jetDrone: return "Реактивний БпЛА"
        case .reconDrone: return "Розвідувальний БпЛА"
        case .molniya: return "БпЛА «Молнія»"
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

// MARK: - ThreatType short names

private extension ThreatType {

    var shortName: String {
        switch self {
        case .shahed: return "Шахед"
        case .jetDrone: return "Реакт."
        case .reconDrone: return "Розвід."
        case .molniya: return "Молнія"
        case .drone: return "БпЛА"
        case .fpv: return "FPV"
        case .guidedAerialBomb: return "КАБ"
        case .cruiseMissile: return "Крилата"
        case .highSpeedTarget: return "Швидк."
        case .missile: return "Ракета"
        case .ballisticMissile: return "Бал."
        case .aviation: return "Авіація"
        }
    }
}

// MARK: - ThreatKind short names

private extension ThreatKind {

    var shortName: String {
        switch self {
        case .drone: return "БпЛА"
        case .fpv: return "FPV"
        case .guidedAerialBomb: return "КАБ"
        case .missile: return "Ракета"
        case .ballisticMissile: return "Бал."
        case .aviation: return "Авіація"
        case .unknown: return "Ціль"
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
