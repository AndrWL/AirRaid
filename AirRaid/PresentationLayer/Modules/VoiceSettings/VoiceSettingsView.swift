//
//  VoiceSettingsView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The voice feed's settings: what is read aloud, for which places, how fast.
struct VoiceSettingsView<ViewModel: VoiceSettingsViewModelProtocol>: View {

    // MARK: - Variables

    private let viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if viewModel.isMutedBySoundMode {
                Section {
                    InlineNote(
                        "Сигнал у налаштуваннях не «Звук», тож ефір не читає вголос сам. «Прочитати вголос» працює завжди.",
                        systemImage: "speaker.slash",
                        tone: .warning
                    )
                }
                .listRowBackground(Color.surface)
            }
            rulesSection
            listeningSection
        }
        .font(.app(.body))
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Голосовий ефір")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sections

private extension VoiceSettingsView {

    var rulesSection: some View {
        Section {
            Picker(
                "Читати",
                selection: Binding(
                    get: { viewModel.settings.minimumPriority },
                    set: { viewModel.didSelectMinimumPriority($0) }
                )
            ) {
                ForEach(viewModel.priorityOptions, id: \.self) { priority in
                    Text(priority.voiceTitle).tag(priority)
                }
            }
            .foregroundStyle(.ink)
            Toggle(
                "Лише мої місця",
                isOn: Binding(
                    get: { viewModel.settings.isOnlyMyPlaces },
                    set: { viewModel.didToggleOnlyMyPlaces($0) }
                )
            )
            .tint(.accentColor)
            .foregroundStyle(.ink)
            Picker(
                "Швидкість",
                selection: Binding(
                    get: { viewModel.settings.speechRate },
                    set: { viewModel.didSelectRate($0) }
                )
            ) {
                ForEach(viewModel.rateOptions, id: \.self) { rate in
                    Text(rate.title).tag(rate)
                }
            }
            .pickerStyle(.segmented)
            if !viewModel.isPlusActive {
                Button(action: viewModel.didTapUnlock) {
                    Label("Налаштувати в AirRaid Плюс", systemImage: "lock.open")
                }
                .font(.app(.body, weight: .semibold))
            }
        } header: {
            Text("Правила")
        } footer: {
            footerText("Загроза в радіусі ваших місць читається завжди й перебиває інші повідомлення.")
        }
        .listRowBackground(Color.surface)
    }

    var listeningSection: some View {
        Section {
            Toggle(
                "Читати відбої",
                isOn: Binding(
                    get: { viewModel.settings.readsEndings },
                    set: { viewModel.didToggleReadsEndings($0) }
                )
            )
            .tint(.accentColor)
            .foregroundStyle(.ink)
            Toggle(
                "Не гасити екран",
                isOn: Binding(
                    get: { viewModel.settings.keepsScreenAwake },
                    set: { viewModel.didToggleKeepsScreenAwake($0) }
                )
            )
            .tint(.accentColor)
            .foregroundStyle(.ink)
            Button(action: viewModel.didTapSample) {
                Label("Прослухати приклад", systemImage: "play.circle")
            }
            .font(.app(.body, weight: .semibold))
        } header: {
            Text("Прослуховування")
        } footer: {
            footerText(
                "Голосовий ефір працює, поки AirRaid відкритий: із заблокованим екраном iOS зупиняє застосунок. "
                    + "Тому під час ефіру екран не гасне. Якісніший голос: Параметри iOS › Доступність › Озвучення."
            )
        }
        .listRowBackground(Color.surface)
    }

    func footerText(_ text: String) -> some View {
        Text(text)
            .font(.app(.footnote))
            .foregroundStyle(.inkMuted)
    }
}

// MARK: - Display names

private extension FeedPriority {

    var voiceTitle: String {
        switch self {
        case .low: "Усе"
        case .normal: "Дрони й тривоги та вище"
        case .high: "Ракети, КАБи, авіація та вище"
        case .critical: "Лише критичне"
        }
    }
}

private extension VoiceSpeechRate {

    var title: String {
        switch self {
        case .slow: "Повільно"
        case .normal: "Нормально"
        case .fast: "Швидко"
        }
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return NavigationStack {
        VoiceSettingsCoordinatorView(appContainer: container)
    }
}
