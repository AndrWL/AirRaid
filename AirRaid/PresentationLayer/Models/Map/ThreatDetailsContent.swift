//
//  ThreatDetailsContent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import Foundation

/// Everything the threat details sheet shows, already worded for the user.
///
/// Built for a given moment, because the time since the last report and the time to the target change while
/// the sheet is open. Keeps the wording rules — what is an estimate, what is uncertain — in one place.
struct ThreatDetailsContent {

    // MARK: - Variables

    /// The type, or the category when the type is unknown.
    let title: String

    /// «×3» for a group; `nil` for one target or an unknown number.
    let countText: String?

    /// The asset name of the threat's silhouette.
    let iconName: String

    /// The silhouette's rotation in degrees; `0` for icons that stay upright.
    let iconRotation: Double

    /// The server's ready-made caption, when it sends one.
    let summary: String?

    let confidence: Confidence

    /// «Підтвердили 4 канали».
    let sourcesText: String

    /// The last confirmed place, or `nil` when only the target or the region is known.
    let positionName: String?

    /// Where the threat is heading.
    let targetName: String?

    let regionName: String

    /// Why the pin may not be where the threat is; `nil` for a confirmed position.
    let locationNote: String?

    /// Set when the threat's oblast has no air raid alert at all: the place was probably matched to a namesake
    /// in the wrong oblast, which is also why the map fades such a pin.
    let noAlertNote: String?

    /// «Пд-Зх (215°)» from ``Threat/course``; `nil` when the course is unknown.
    let courseText: String?

    /// «Пн-Сх»; `nil` when unknown.
    let approachText: String?

    /// «~180 км/год»; `nil` when the threat is not moved between reports.
    let speedText: String?

    /// The speed is typical for the type rather than measured along the track.
    let isSpeedEstimated: Bool

    /// «≈ 12 хв»; `nil` when there is no target or the forecast has run out.
    let timeToTargetText: String?

    /// «11:42».
    let firstSeenText: String

    /// «2 хв тому».
    let updatedText: String

    /// Set when the data is old or the threat has disappeared, so the sheet does not pass it off as current.
    let staleNote: String?

    /// Official alerts in the threat's region, earliest first.
    let alerts: [AlertRow]

    /// The threat is reported for the whole country, so there is no region to show alerts for.
    let isCountryWide: Bool

    init(
        threat: Threat,
        alerts: [RegionAlert],
        isGone: Bool,
        now: Date
    ) {
        let icon = ThreatIcon(threat)
        title = threat.displayName
        countText = threat.count.flatMap { $0 > 1 ? "×\($0)" : nil }
        iconName = icon.name
        iconRotation = icon.rotatesWithHeading ? threat.course ?? 0 : 0
        summary = threat.summary
        confidence = Confidence(level: threat.level, value: threat.confidence)
        sourcesText = Self.makeSourcesText(count: threat.sourceCount)

        positionName = threat.position?.name
        targetName = threat.target?.name
        regionName = threat.area.name
        locationNote = Self.makeLocationNote(for: threat)
        noAlertNote = threat.isCountryWide || alerts.contains(where: { $0.kind == .airRaid })
            ? nil
            : "В області зараз немає повітряної тривоги — місце могли визначити помилково"

        courseText = threat.course.map { "\(Self.compassPoint(for: $0)) (\(Int($0.rounded()))°)" }
        approachText = threat.approachBearing.map(Self.compassPoint)
        speedText = threat.speedKmh > 0 ? "~\(Int(threat.speedKmh.rounded())) км/год" : nil
        isSpeedEstimated = threat.speedSource == .typical
        timeToTargetText = isGone ? nil : threat.timeToTarget(at: now).map(Self.makeTimeToTargetText)

        firstSeenText = threat.firstSeenAt.formatted(Self.timeStyle)
        updatedText = Self.relativeFormatter.localizedString(for: min(threat.updatedAt, now), relativeTo: now)
        staleNote = Self.makeStaleNote(for: threat, isGone: isGone, now: now)

        self.alerts = alerts.map { AlertRow(alert: $0, now: now) }
        isCountryWide = threat.isCountryWide
    }
}

// MARK: - Confidence

extension ThreatDetailsContent {

    /// How far the report can be trusted, as a badge.
    struct Confidence {

        let level: ThreatLevel

        /// «Висока».
        let label: String

        /// «82 %».
        let percentText: String

        init(
            level: ThreatLevel,
            value: Double
        ) {
            self.level = level
            switch level {
            case .low: label = "Низька"
            case .medium: label = "Середня"
            case .high: label = "Висока"
            }
            percentText = "\(Int((min(max(value, 0), 1) * 100).rounded())) %"
        }
    }
}

// MARK: - AlertRow

extension ThreatDetailsContent {

    /// One official alert in the threat's region.
    struct AlertRow: Identifiable {

        let id: String

        /// «Полтавський район».
        let name: String

        /// The alert kind when it is not a plain air raid, e.g. «Загроза артобстрілу».
        let kindText: String?

        /// `nil` for alerts other than air raids, which have no level.
        let level: RegionAlertLevel?

        /// «з 10:28».
        let startedText: String

        /// «1 год 52 хв».
        let durationText: String

        init(
            alert: RegionAlert,
            now: Date
        ) {
            id = alert.id
            name = alert.name
            kindText = ThreatDetailsContent.makeKindText(for: alert.kind)
            level = alert.kind == .airRaid ? alert.level ?? .red : nil
            startedText = "з \(alert.startedAt.formatted(ThreatDetailsContent.timeStyle))"
            durationText = ThreatDetailsContent.formatDuration(max(now.timeIntervalSince(alert.startedAt), 0))
        }
    }
}

// MARK: - Private methods

private extension ThreatDetailsContent {

    static func makeLocationNote(for threat: Threat) -> String? {
        switch threat.positionQuality {
        case .confirmed:
            return nil
        case .approximate:
            let accuracy = Int(threat.accuracyKm.rounded())
            return accuracy > 0 ? "Розташування приблизне, ±\(accuracy) км" : "Розташування приблизне"
        case .targetOnly:
            return "Відомий лише напрямок — позначка стоїть на цілі атаки, а не там, де загроза зараз"
        case .area:
            return "Відома лише область — позначка стоїть умовно (у зоні тривоги, якщо вона є), це не місце загрози"
        }
    }

    static func makeStaleNote(
        for threat: Threat,
        isGone: Bool,
        now: Date
    ) -> String? {
        if isGone {
            return "Ціль більше не відстежується — показано останні відомі дані"
        }
        if now >= threat.expiresAt {
            return "Дані застаріли — ціль могла зникнути"
        }
        if now.timeIntervalSince(threat.updatedAt) > Constants.staleAfter {
            return "Останнє відоме положення · очікує підтвердження"
        }
        return nil
    }

    static func makeKindText(for kind: RegionAlertKind) -> String? {
        switch kind {
        case .airRaid: return nil
        case .artilleryShelling: return "Загроза артобстрілу"
        case .urbanFights: return "Загроза вуличних боїв"
        case .chemical: return "Хімічна загроза"
        case .nuclear: return "Радіаційна загроза"
        case .unknown: return "Інша загроза"
        }
    }

    /// The nearest of eight compass points, as Ukrainian abbreviations.
    static func compassPoint(for bearing: Double) -> String {
        let normalized = (bearing.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let index = Int((normalized / 45).rounded()) % Constants.compassPoints.count
        return Constants.compassPoints[index]
    }

    static func makeTimeToTargetText(_ interval: TimeInterval) -> String {
        guard interval >= 60 else { return "менше хвилини" }
        return "≈ \(formatDuration(interval))"
    }

    /// «1 год 52 хв», «20 хв»; whole minutes, since seconds would only flicker.
    static func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        guard minutes >= 60 else { return "\(minutes) хв" }
        let hours = minutes / 60
        let rest = minutes % 60
        guard hours < 24 else { return "\(hours / 24) д \(hours % 24) год" }
        return rest > 0 ? "\(hours) год \(rest) хв" : "\(hours) год"
    }

    static func makeSourcesText(count: Int) -> String {
        let lastTwo = count % 100
        let last = count % 10
        let noun: String
        if (11...14).contains(lastTwo) || last == 0 || last >= 5 {
            noun = "каналів"
        } else if last == 1 {
            noun = "канал"
        } else {
            noun = "канали"
        }
        return count == 1 ? "Повідомив 1 канал" : "Підтвердили \(count) \(noun)"
    }

    static let timeStyle = Date.FormatStyle(locale: Constants.locale).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)

    static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Constants.locale
        formatter.unitsStyle = .short
        return formatter
    }()
}

// MARK: - Constants

private enum Constants {
    static let locale = Locale(identifier: "uk_UA")
    static let compassPoints = ["Пн", "Пн-Сх", "Сх", "Пд-Сх", "Пд", "Пд-Зх", "Зх", "Пн-Зх"]

    /// Channels report every few minutes; ten minutes of silence means the position is no longer current.
    static let staleAfter: TimeInterval = 10 * 60
}
