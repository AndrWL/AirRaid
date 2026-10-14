//
//  SettingsView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// The Settings tab: the notification permission, the home, the Live Activity, the alert sound and the app's version.
struct SettingsView<ViewModel: SettingsViewModelProtocol>: View {

    // MARK: - Variables

    private let viewModel: ViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            notificationsSection
            homeSection
            liveActivitySection
            soundSection
            aboutSection
        }
        .font(.app(.body))
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Налаштування")
        // Again on every return to the app: the permission may have just been changed in the Settings app.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await viewModel.onAppear()
        }
    }
}

// MARK: - Sections

private extension SettingsView {

    var notificationsSection: some View {
        Section {
            LabeledContent {
                Text(notificationStatus)
                    .foregroundStyle(.inkMuted)
            } label: {
                Label("Дозвіл на сповіщення", systemImage: "bell.badge")
                    .foregroundStyle(.ink)
            }
            switch viewModel.notificationAuthorization {
            case .notDetermined:
                Button("Дозволити сповіщення") {
                    Task { await viewModel.didTapAllowNotifications() }
                }
                .font(.app(.body, weight: .semibold))
            case .denied, .authorized:
                Button("Відкрити параметри iOS", action: openNotificationSettings)
                    .font(.app(.body, weight: .semibold))
            case nil:
                EmptyView()
            }
        } header: {
            Text("Сповіщення")
        } footer: {
            footerText("Поки AirRaid попереджає лише тоді, коли відкритий. Дозвіл знадобиться для сповіщень у фоні.")
        }
        .listRowBackground(Color.surface)
    }

    var homeSection: some View {
        Section {
            if let home = viewModel.home {
                homeAddress(home)
                Picker(
                    "Радіус",
                    selection: Binding(
                        get: { home.radiusKm },
                        set: { viewModel.didSelectHomeRadius($0) }
                    )
                ) {
                    ForEach(viewModel.radiusOptions, id: \.self) { radius in
                        Text(DisplayTime.distance(radius)).tag(radius)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Радіус навколо дому")
                Button(action: viewModel.didTapPickHomeOnMap) {
                    Label("Перемістити на мапі", systemImage: "mappin.and.ellipse")
                }
                .font(.app(.body, weight: .semibold))
                Button("Видалити дім", role: .destructive, action: viewModel.didTapRemoveHome)
                    .font(.app(.body, weight: .semibold))
            } else {
                InlineNote("Дім не позначено", systemImage: "house", tone: .allClear)
                Button(action: viewModel.didTapPickHomeOnMap) {
                    Label("Обрати на мапі", systemImage: "mappin.and.ellipse")
                }
                .font(.app(.body, weight: .semibold))
            }
        } header: {
            Text("Дім")
        } footer: {
            footerText("Загрози в радіусі дому з'являються в картці на мапі. Дім зберігається лише на цьому пристрої.")
        }
        .listRowBackground(Color.surface)
    }

    /// One switch for both: the Dynamic Island is the same Live Activity, iOS shows it wherever the device has one.
    var liveActivitySection: some View {
        Section {
            Toggle(
                isOn: Binding(
                    get: { viewModel.isLiveActivityEnabled },
                    set: { viewModel.didToggleLiveActivity($0) }
                )
            ) {
                Label("Live Activity і Dynamic Island", systemImage: "rectangle.topthird.inset.filled")
                    .foregroundStyle(.ink)
            }
            .tint(.accentColor)
            .disabled(viewModel.isLiveActivityAllowedBySystem == false)
            if viewModel.isLiveActivityAllowedBySystem == false {
                InlineNote("Live Activity вимкнено в параметрах iOS", systemImage: "exclamationmark.triangle", tone: .warning)
                Button("Відкрити параметри iOS", action: openAppSettings)
                    .font(.app(.body, weight: .semibold))
            } else if viewModel.isLiveActivityEnabled {
                InlineNote(
                    "Може збільшити витрату батареї: екран блокування й Dynamic Island оновлюються з кожною зміною загроз",
                    systemImage: "battery.50percent",
                    tone: .warning
                )
            }
        } header: {
            Text("Екран блокування")
        } footer: {
            footerText("Під час тривоги або коли загроза в радіусі, AirRaid показує її на екрані блокування та в Dynamic Island. Поки оновлюється лише тоді, коли AirRaid відкритий.")
        }
        .listRowBackground(Color.surface)
    }

    var soundSection: some View {
        Section {
            Picker(
                "Сигнал",
                selection: Binding(
                    get: { viewModel.soundMode },
                    set: { viewModel.didSelectSoundMode($0) }
                )
            ) {
                ForEach(viewModel.soundModes, id: \.self) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .foregroundStyle(.ink)
                        .tag(mode)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            Button(action: viewModel.didTapPlaySample) {
                Label("Перевірити сигнал", systemImage: "play.circle")
            }
            .font(.app(.body, weight: .semibold))
            .disabled(viewModel.soundMode == .off)
        } header: {
            Text("Звук")
        } footer: {
            footerText("Сигнал лунає, коли загроза заходить у радіус ваших місць, поки AirRaid відкритий. У беззвучному режимі iPhone лише вібрує.")
        }
        .listRowBackground(Color.surface)
    }

    var aboutSection: some View {
        Section {
            LabeledContent("Версія", value: viewModel.appVersion)
                .foregroundStyle(.ink)
            if let feedbackURL = viewModel.feedbackURL {
                Button {
                    openURL(feedbackURL)
                } label: {
                    Label("Написати розробнику", systemImage: "envelope")
                }
                .font(.app(.body, weight: .semibold))
            }
        } header: {
            Text("Про застосунок")
        } footer: {
            footerText("AirRaid не замінює сирени та офіційні сповіщення. Дані про тривоги — alerts.in.ua.")
        }
        .listRowBackground(Color.surface)
    }
}

// MARK: - Components

private extension SettingsView {

    var notificationStatus: String {
        switch viewModel.notificationAuthorization {
        case .authorized: "Увімкнено"
        case .denied: "Вимкнено"
        case .notDetermined: "Не запитано"
        case nil: ""
        }
    }

    func homeAddress(_ home: SettingsHomeContent) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(home.street ?? "Адресу визначаємо…")
                    .foregroundStyle(.ink)
                if let placeLine = home.placeLine {
                    Text(placeLine)
                        .font(.app(.footnote))
                        .foregroundStyle(.inkMuted)
                }
            }
        } icon: {
            Image(systemName: WatchedPlaceKind.home.systemImage)
                .foregroundStyle(WatchedPlaceKind.home.tint)
        }
        .accessibilityElement(children: .combine)
    }

    func footerText(_ text: String) -> some View {
        Text(text)
            .font(.app(.footnote))
            .foregroundStyle(.inkMuted)
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            viewModel: SettingsViewModel(
                router: SettingsRouter(
                    stackRouter: StackRouter(),
                    tabBarRouter: TabBarRouter(
                        mapStackRouter: StackRouter(),
                        alertsStackRouter: StackRouter(),
                        settingsStackRouter: StackRouter(),
                        mapIntentChannel: MapIntentChannel()
                    )
                ),
                placeSettingsRepository: PlaceSettingsRepository(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                regionBoundaryRepository: RegionBoundaryRepository(),
                alertSoundService: AlertSoundService(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                liveActivitySettingsService: LiveActivitySettingsService(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                notificationPermissionService: NotificationPermissionService(),
                versionInfo: AppVersionInfo(version: "1.0", build: "1", osVersion: "26.0"),
                feedbackEmail: AppEnvironment.feedbackEmail
            )
        )
    }
}
