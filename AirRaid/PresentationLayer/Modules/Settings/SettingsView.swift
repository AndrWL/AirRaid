//
//  SettingsView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// The Settings tab: the notification permission, the places, the Live Activity, the alert sound and the app's version.
struct SettingsView<ViewModel: SettingsViewModelProtocol>: View {

    // MARK: - Variables

    private let viewModel: ViewModel
    @State private var isMailUnavailableAlertPresented = false
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            notificationsSection
            placesSection
            feedSection
            liveActivitySection
            mapSection
            soundSection
            aboutSection
        }
        .font(.app(.body))
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Налаштування")
        .alert("Не вдалося відкрити Пошту", isPresented: $isMailUnavailableAlertPresented) {
            Button("Скопіювати адресу") {
                UIPasteboard.general.string = viewModel.feedbackEmail
            }
            Button("Закрити", role: .cancel) {}
        } message: {
            Text("Напишіть на \(viewModel.feedbackEmail) з будь-якої поштової програми.")
        }
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

    var placesSection: some View {
        Section {
            ForEach(viewModel.places) { place in
                Button {
                    viewModel.didTapPlace(place.id)
                } label: {
                    placeRow(place)
                }
            }
            if !viewModel.hasHome {
                Button(action: viewModel.didTapPickHomeOnMap) {
                    Label("Обрати дім на мапі", systemImage: "house")
                }
                .font(.app(.body, weight: .semibold))
            }
            addPlaceButton
        } header: {
            HStack {
                Text("Мої місця")
                Spacer()
                if let placeCountText = viewModel.placeCountText {
                    Text(placeCountText)
                        .monospacedDigit()
                }
            }
        } footer: {
            footerText(placesFooter)
        }
        .listRowBackground(Color.surface)
    }

    var feedSection: some View {
        Section {
            Button(action: viewModel.didTapVoiceSettings) {
                HStack {
                    Label("Голосовий ефір", systemImage: "waveform")
                        .foregroundStyle(.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.app(.footnote, weight: .semibold))
                        .foregroundStyle(.inkMuted)
                }
            }
            Button(action: viewModel.didTapPlus) {
                Label("AirRaid Плюс", systemImage: "sparkles")
                    .font(.app(.body, weight: .semibold))
            }
        } header: {
            Text("Ефір")
        } footer: {
            footerText("Ефір пам'ятає добу безкоштовно. Плюс додає історію за 90 днів, фільтри, нічний звіт і правила голосу.")
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

    var mapSection: some View {
        Section {
            Picker(
                "Стиль мапи",
                selection: Binding(
                    get: { viewModel.mapStylePreference },
                    set: { viewModel.didSelectMapStyle($0) }
                )
            ) {
                ForEach(viewModel.mapStylePreferences, id: \.self) { preference in
                    Label(preference.title, systemImage: preference.systemImage)
                        .foregroundStyle(.ink)
                        .tag(preference)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Мапа")
        } footer: {
            footerText("На темній мапі заливка тривог видна найкраще. Детальна показує ліси, воду й забудову і темніє разом із темою iPhone.")
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
            if let upgradeNotice = viewModel.upgradeNotice {
                InlineNote(UpgradeNotice.versionNote, systemImage: UpgradeNotice.systemImage, tone: .warning)
                if let appStoreURL = upgradeNotice.appStoreURL {
                    Button {
                        openURL(appStoreURL)
                    } label: {
                        Label("Оновити в App Store", systemImage: "arrow.up.forward.app")
                    }
                    .font(.app(.body, weight: .semibold))
                }
            }
            if let feedbackURL = viewModel.feedbackURL {
                Button {
                    // Without a mail account nothing opens `mailto:`, and the tap would do nothing at all.
                    openURL(feedbackURL) { accepted in
                        if !accepted {
                            isMailUnavailableAlertPresented = true
                        }
                    }
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

    func placeRow(_ place: SettingsPlaceContent) -> some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(place.title)
                        .foregroundStyle(.ink)
                    if let detail = placeDetail(place) {
                        Text(detail)
                            .font(.app(.footnote))
                            .foregroundStyle(.inkMuted)
                    }
                    if place.isPaused {
                        Text("Призупинено — потрібен Плюс")
                            .font(.app(.footnote, weight: .semibold))
                            .foregroundStyle(.warningInk)
                    }
                }
            } icon: {
                Image(systemName: place.kind.systemImage)
                    .foregroundStyle(place.isPaused ? Color.inkMuted : place.kind.tint)
            }
            Spacer()
            Text(DisplayTime.distance(place.radiusKm))
                .font(.app(.footnote))
                .foregroundStyle(.inkMuted)
            Image(systemName: "chevron.right")
                .font(.app(.footnote, weight: .semibold))
                .foregroundStyle(.inkMuted)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Назва, радіус, перемістити чи прибрати")
    }

    /// The street, else the locality and region; «Адресу визначаємо…» while neither is known.
    func placeDetail(_ place: SettingsPlaceContent) -> String? {
        if let street = place.street {
            return [street, place.placeLine].compactMap { $0 }.joined(separator: " · ")
        }
        return place.placeLine ?? "Адресу визначаємо…"
    }

    /// «Додати місце» with a Плюс badge: without Плюс it opens the subscription.
    var addPlaceButton: some View {
        Button(action: viewModel.didTapAddPlace) {
            HStack {
                Label("Додати місце", systemImage: "plus.circle")
                Spacer()
                if !viewModel.isPlusActive {
                    Badge("Плюс", tone: .accent)
                }
            }
        }
        .font(.app(.body, weight: .semibold))
        .disabled(viewModel.isAtPlaceLimit)
    }

    var placesFooter: String {
        if viewModel.isAtPlaceLimit {
            return "Це максимум місць, за якими стежить AirRaid. Приберіть одне, щоб додати інше."
        }
        if viewModel.isPlusActive {
            return "Загрози в радіусі кожного місця з'являються в картці на мапі та в ефірі «Мої місця». "
                + "Місця зберігаються лише на цьому пристрої."
        }
        return "Дім і ваша геолокація — безкоштовно. З Плюсом — до \(PremiumLimits.plusPlaces) місць: батьки, робота, школа. "
            + "Місця зберігаються лише на цьому пристрої."
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
    let container = DIAppContainer()
    container.setup()

    return NavigationStack {
        SettingsView(
            viewModel: SettingsViewModel(
                router: SettingsRouter(
                    stackRouter: StackRouter(),
                    tabBarRouter: TabBarRouter(
                        mapStackRouter: StackRouter(),
                        feedStackRouter: StackRouter(),
                        settingsStackRouter: StackRouter(),
                        mapIntentChannel: MapIntentChannel()
                    )
                ),
                placeSettingsRepository: PlaceSettingsRepository(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                entitlementService: StoreKitEntitlementService(productIDs: []),
                regionBoundaryRepository: RegionBoundaryRepository(),
                alertSoundService: AlertSoundService(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                liveActivitySettingsService: LiveActivitySettingsService(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                mapStyleSettingsService: MapStyleSettingsService(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                notificationPermissionService: NotificationPermissionService(),
                realtimeService: container.services.realtimeService,
                versionInfo: AppVersionInfo(version: "1.0", build: "1", osVersion: "26.0"),
                feedbackEmail: AppEnvironment.feedbackEmail,
                appStoreURL: AppEnvironment.appStoreURL
            )
        )
    }
}
