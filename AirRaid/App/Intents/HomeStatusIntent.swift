//
//  HomeStatusIntent.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import AppIntents
import Foundation
import HomeStatusKit

/// «Що в ефірі?» for Siri, Shortcuts and the Action button: the home's status, said without opening the app.
///
/// Reads the snapshot the widgets read, so it answers even when the app is not running — and says so when that
/// snapshot is old, since the app updates it only while open.
nonisolated struct HomeStatusIntent: AppIntent {

    static let title: LocalizedStringResource = "Що в ефірі"

    static let description = IntentDescription("Тривога й найближча загроза біля дому.")

    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: Self.answer(snapshot: try? HomeStatusStore().load(), now: .now)))
    }
}

// MARK: - Private methods

nonisolated private extension HomeStatusIntent {

    static func answer(
        snapshot: HomeStatusSnapshot?,
        now: Date
    ) -> String {
        guard let snapshot else {
            return "Немає даних. Відкрийте AirRaid, щоб оновити."
        }
        guard let home = snapshot.home else {
            return "Дім не позначено. Позначте його на мапі в AirRaid."
        }
        var sentences: [String] = []
        if let alert = home.alert {
            sentences.append("\(home.placeName): повітряна тривога з \(alert.startedAt.formatted(Constants.clockStyle)).")
        } else {
            sentences.append("\(home.placeName): тривоги немає.")
        }
        if let threat = home.nearestThreat {
            sentences.append("Найближча загроза: \(threat.title), \(threat.distanceText).")
        } else if home.alert != nil {
            sentences.append("У радіусі дому загроз не видно.")
        }
        if now.timeIntervalSince(snapshot.updatedAt) > Constants.staleAfter {
            sentences.append("Дані від \(snapshot.updatedAt.formatted(Constants.clockStyle)), відкрийте AirRaid, щоб оновити.")
        }
        return sentences.joined(separator: " ")
    }
}

/// The phrases Siri knows without setup.
nonisolated struct AirRaidShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: HomeStatusIntent(),
            phrases: [
                "Що в ефірі \(.applicationName)",
                "Що біля дому в \(.applicationName)",
                "Статус тривоги в \(.applicationName)"
            ],
            shortTitle: "Що в ефірі",
            systemImageName: "dot.radiowaves.left.and.right"
        )
    }
}

// MARK: - Constants

nonisolated private enum Constants {
    /// The app refreshes the snapshot every minute while open; older means it is closed.
    static let staleAfter: TimeInterval = 5 * 60
    static let clockStyle = Date.FormatStyle(locale: Locale(identifier: "uk_UA")).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
}
