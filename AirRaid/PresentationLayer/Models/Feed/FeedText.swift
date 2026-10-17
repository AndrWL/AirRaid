//
//  FeedText.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// The words of the feed, from one structure in two styles: short lines for the screen and whole sentences for the
/// voice — no emoji, arrows or abbreviations, a forecast always said as a guess.
enum FeedText {

    // MARK: - Screen

    /// «Шахед ×3», «Повітряна тривога».
    static func title(of item: FeedItem) -> String {
        switch item.content {
        case .threat(let threat):
            let name = threat.type?.displayName ?? threat.kind.displayName
            guard let count = threat.count, count > 1 else { return name }
            return "\(name) ×\(count)"
        case .alert(let alert):
            return alert.kind.feedTitle
        }
    }

    /// The bubble's current state under the title: «Ніжин → Бровари», «2 громади · триває».
    static func subtitle(of item: FeedItem) -> String? {
        switch item.content {
        case .threat(let threat):
            if threat.isCountryWide {
                return "Загроза по всій Україні"
            }
            let place = threat.positionName ?? threat.regionName
            return threat.targetName.map { "\(place) → \($0)" } ?? place
        case .alert(let alert):
            let active = alert.places.filter { $0.endedAt == nil }
            guard item.isActive else { return "Відбій" }
            guard active.count > 1 else { return active.first?.name }
            return "\(active.count) \(plural(active.count, one: "місце", few: "місця", many: "місць")) · триває"
        }
    }

    /// One line of the bubble.
    static func display(_ line: FeedLine) -> String {
        switch line.event {
        case .threatAppeared(let regionName, let positionName, let targetName):
            let place = positionName ?? regionName
            return targetName.map { "Помічено: \(place) → \($0)" } ?? "Помічено: \(place)"
        case .threatRefined(let kind, let type):
            return "Уточнено: \(type?.displayName ?? kind.displayName)"
        case .threatCountChanged(let count):
            return "Кількість: \(count)"
        case .threatConfirmed(_, let sourceCount):
            return "Підтверджено: \(sourceCount) \(plural(sourceCount, one: "джерело", few: "джерела", many: "джерел"))"
        case .threatCrossedRegion(let regionName):
            return "Перетнула межу: \(regionName)"
        case .threatCourseChanged(let targetName):
            return "Змінила курс → \(targetName)"
        case .threatClosed(let reason):
            return reason.displayText
        case .alertStarted(let placeName):
            return "Тривога: \(placeName)"
        case .alertLevelChanged(let level):
            return "Рівень: \(level.displayName)"
        case .alertEnded(let placeName, let duration):
            return "Відбій: \(placeName) (\(DisplayTime.duration(duration)))"
        }
    }

    // MARK: - Voice

    /// A sentence or two for the line, naming its bubble so it makes sense on its own.
    static func speech(_ entry: FeedEntry) -> String {
        let subject = spokenSubject(of: entry.item)
        switch entry.line.event {
        case .threatAppeared(let regionName, let positionName, let targetName):
            let place = positionName ?? regionName
            let course = targetName.map { " Ймовірно курсом на \($0)." } ?? ""
            return "\(subject). Помічено: \(place).\(course)"
        case .threatRefined(let kind, let type):
            return "Уточнення: \((type?.spokenName ?? kind.spokenName)). \(spokenPlace(of: entry.item))"
        case .threatCountChanged(let count):
            return "\(subject): тепер \(count) \(plural(count, one: "ціль", few: "цілі", many: "цілей"))."
        case .threatConfirmed:
            return "\(subject): підтверджено кількома джерелами."
        case .threatCrossedRegion(let regionName):
            return "\(subject): перетнула межу. Тепер \(regionName)."
        case .threatCourseChanged(let targetName):
            return "\(subject) змінила курс. Ймовірно на \(targetName)."
        case .threatClosed(let reason):
            return "\(subject): \(reason.displayText.lowercased())."
        case .alertStarted(let placeName):
            return "\(subject): \(placeName)."
        case .alertLevelChanged(let level):
            return "Рівень тривоги: \(level.displayName)."
        case .alertEnded(let placeName, _):
            return "Відбій тривоги: \(placeName)."
        }
    }

    // MARK: - Helpers

    /// «1 година 52 хвилини» — whole words, the voice reads «год» as a syllable.
    static func spokenDuration(_ interval: TimeInterval) -> String {
        let minutes = max(Int(interval / 60), 1)
        let hours = minutes / 60
        let rest = minutes % 60
        let minuteText = "\(rest) \(plural(rest, one: "хвилина", few: "хвилини", many: "хвилин"))"
        guard hours > 0 else { return minuteText }
        let hourText = "\(hours) \(plural(hours, one: "година", few: "години", many: "годин"))"
        return rest > 0 ? "\(hourText) \(minuteText)" : hourText
    }

    /// «1 джерело», «3 джерела», «5 джерел».
    static func plural(
        _ count: Int,
        one: String,
        few: String,
        many: String
    ) -> String {
        let lastTwo = count % 100
        let last = count % 10
        if (11...14).contains(lastTwo) {
            return many
        }
        switch last {
        case 1: return one
        case 2...4: return few
        default: return many
        }
    }
}

// MARK: - Private methods

private extension FeedText {

    static func spokenSubject(of item: FeedItem) -> String {
        switch item.content {
        case .threat(let threat):
            let name = threat.type?.spokenName ?? threat.kind.spokenName
            guard let count = threat.count, count > 1 else { return name }
            return "\(name), \(count) \(plural(count, one: "ціль", few: "цілі", many: "цілей"))"
        case .alert(let alert):
            return alert.kind.feedTitle
        }
    }

    static func spokenPlace(of item: FeedItem) -> String {
        guard case .threat(let threat) = item.content, !threat.isCountryWide else { return "" }
        return "Зараз: \(threat.positionName ?? threat.regionName)."
    }
}

// MARK: - Display names

extension RegionAlertKind {

    /// «Повітряна тривога», «Загроза артобстрілу».
    var feedTitle: String {
        switch self {
        case .airRaid: "Повітряна тривога"
        case .artilleryShelling: "Загроза артобстрілу"
        case .urbanFights: "Загроза вуличних боїв"
        case .chemical: "Хімічна загроза"
        case .nuclear: "Радіаційна загроза"
        case .unknown: "Тривога"
        }
    }
}

extension RegionAlertLevel {

    var displayName: String {
        switch self {
        case .yellow: "жовтий"
        case .red: "червоний"
        }
    }
}

private extension ThreatCloseReason {

    var displayText: String {
        switch self {
        case .ended: "Ціль зникла"
        case .cancelled: "Повідомлення скасовано джерелом"
        case .merged: "Об'єднано з іншою ціллю"
        case .unknown: "Більше не відстежується"
        }
    }
}

private extension ThreatType {

    /// The name said aloud: words, not letters — «КАБ» is read as one, «БпЛА» is not.
    var spokenName: String {
        switch self {
        case .shahed: "Шахед"
        case .jetDrone: "Реактивний безпілотник"
        case .reconDrone: "Розвідувальний безпілотник"
        case .molniya: "Безпілотник Молнія"
        case .drone: "Безпілотник"
        case .fpv: "FPV-дрон"
        case .guidedAerialBomb: "Керовані авіабомби"
        case .cruiseMissile: "Крилата ракета"
        case .highSpeedTarget: "Швидкісна ціль"
        case .missile: "Ракета"
        case .ballisticMissile: "Балістика"
        case .aviation: "Авіація"
        }
    }
}

private extension ThreatKind {

    var spokenName: String {
        switch self {
        case .drone: "Безпілотник"
        case .fpv: "FPV-дрон"
        case .guidedAerialBomb: "Керовані авіабомби"
        case .missile: "Ракета"
        case .ballisticMissile: "Балістика"
        case .aviation: "Авіація"
        case .unknown: "Невідома ціль"
        }
    }
}
