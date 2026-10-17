//
//  SettingsViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Combine
import Foundation

/// The view model of the Settings tab.
@Observable
final class SettingsViewModel<Router: SettingsRouterProtocol>: BaseViewModel {

    // MARK: - Variables

    let soundModes = AlertSoundMode.allCases
    let mapStylePreferences = MapStylePreference.allCases
    private(set) var notificationAuthorization: NotificationAuthorization?
    private(set) var placeSettings: PlaceSettings = .initial
    private(set) var isPlusActive = false
    private(set) var soundMode: AlertSoundMode = .sound
    private(set) var mapStylePreference: MapStylePreference = .system
    private(set) var isLiveActivityEnabled = true
    private(set) var isLiveActivityAllowedBySystem: Bool?
    private(set) var boundaries: [RegionBoundary] = []
    private(set) var upgradeNotice: UpgradeNotice?

    @ObservationIgnored
    private let router: Router

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let entitlementService: EntitlementServiceProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let alertSoundService: AlertSoundServiceProtocol

    @ObservationIgnored
    private let liveActivitySettingsService: LiveActivitySettingsServiceProtocol

    @ObservationIgnored
    private let mapStyleSettingsService: MapStyleSettingsServiceProtocol

    @ObservationIgnored
    private let notificationPermissionService: NotificationPermissionServiceProtocol

    @ObservationIgnored
    private let realtimeService: RealtimeServiceProtocol

    @ObservationIgnored
    private let versionInfo: AppVersionInfo

    @ObservationIgnored
    let feedbackEmail: String

    @ObservationIgnored
    private let appStoreURL: URL?

    init(
        router: Router,
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        entitlementService: EntitlementServiceProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        alertSoundService: AlertSoundServiceProtocol,
        liveActivitySettingsService: LiveActivitySettingsServiceProtocol,
        mapStyleSettingsService: MapStyleSettingsServiceProtocol,
        notificationPermissionService: NotificationPermissionServiceProtocol,
        realtimeService: RealtimeServiceProtocol,
        versionInfo: AppVersionInfo,
        feedbackEmail: String,
        appStoreURL: URL?
    ) {
        self.router = router
        self.placeSettingsRepository = placeSettingsRepository
        self.entitlementService = entitlementService
        self.regionBoundaryRepository = regionBoundaryRepository
        self.alertSoundService = alertSoundService
        self.liveActivitySettingsService = liveActivitySettingsService
        self.mapStyleSettingsService = mapStyleSettingsService
        self.notificationPermissionService = notificationPermissionService
        self.realtimeService = realtimeService
        self.versionInfo = versionInfo
        self.feedbackEmail = feedbackEmail
        self.appStoreURL = appStoreURL
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        placeSettingsRepository.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.placeSettings = settings
            }
            .store(in: &cancellables)

        entitlementService.isPlusActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.isPlusActive = isActive
            }
            .store(in: &cancellables)

        alertSoundService.modePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.soundMode = mode
            }
            .store(in: &cancellables)

        mapStyleSettingsService.preferencePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preference in
                self?.mapStylePreference = preference
            }
            .store(in: &cancellables)

        liveActivitySettingsService.isEnabledPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.isLiveActivityEnabled = isEnabled
            }
            .store(in: &cancellables)

        realtimeService.connectionStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                upgradeNotice = UpgradeNotice.next(after: upgradeNotice, state: state, appStoreURL: appStoreURL)
            }
            .store(in: &cancellables)
    }
}

// MARK: - SettingsViewModelProtocol

extension SettingsViewModel: SettingsViewModelProtocol {

    var places: [SettingsPlaceContent] {
        placeSettings.places.map { place in
            SettingsPlaceContent(
                place: place,
                regionName: boundaries.first { $0.contains(place.coordinate) }?.name,
                isPlusActive: isPlusActive
            )
        }
    }

    var hasHome: Bool {
        placeSettings.home != nil
    }

    var placeCountText: String? {
        guard isPlusActive else { return nil }
        return "\(placeSettings.places.count) з \(PremiumLimits.plusPlaces)"
    }

    var isAtPlaceLimit: Bool {
        isPlusActive && placeSettings.places.count >= PremiumLimits.plusPlaces
    }

    var appVersion: String {
        versionInfo.displayText
    }

    var feedbackURL: URL? {
        var components = URLComponents()
        components.scheme = Constants.mailtoScheme
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "AirRaid \(versionInfo.displayText)"),
            URLQueryItem(name: "body", value: "\n\n—\nAirRaid \(versionInfo.displayText), iOS \(versionInfo.osVersion)")
        ]
        return components.url
    }

    func onAppear() async {
        notificationAuthorization = await notificationPermissionService.authorization()
        isLiveActivityAllowedBySystem = liveActivitySettingsService.isAllowedBySystem
        if boundaries.isEmpty {
            // Only for the region under each place's address; without it the section still works.
            boundaries = (try? await regionBoundaryRepository.fetchBoundaries()) ?? []
        }
    }

    func didTapAllowNotifications() async {
        notificationAuthorization = await notificationPermissionService.requestAuthorization()
    }

    func didTapPickHomeOnMap() {
        router.showPlacePickerOnMap(.home)
    }

    func didTapAddPlace() {
        // The free plan is the home alone; the button is disabled at Плюс's own limit.
        guard isPlusActive else {
            router.presentSheet(.paywall)
            return
        }
        guard !isAtPlaceLimit else { return }
        router.showPlacePickerOnMap(.newPlace)
    }

    func didTapPlace(_ id: SavedPlace.ID) {
        router.showPlace(id)
    }

    func didToggleLiveActivity(_ isEnabled: Bool) {
        isLiveActivityEnabled = isEnabled
        liveActivitySettingsService.setEnabled(isEnabled)
    }

    func didSelectSoundMode(_ mode: AlertSoundMode) {
        soundMode = mode
        alertSoundService.setMode(mode)
        alertSoundService.playSample(of: mode)
    }

    func didSelectMapStyle(_ preference: MapStylePreference) {
        mapStylePreference = preference
        mapStyleSettingsService.setPreference(preference)
    }

    func didTapPlaySample() {
        alertSoundService.playSample(of: soundMode)
    }

    func didTapVoiceSettings() {
        router.showVoiceSettings()
    }

    func didTapPlus() {
        router.presentSheet(.paywall)
    }
}

// MARK: - Constants

private enum Constants {
    static let mailtoScheme = "mailto"
}
