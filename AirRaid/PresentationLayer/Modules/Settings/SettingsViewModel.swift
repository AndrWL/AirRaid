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
final class SettingsViewModel: BaseViewModel {

    // MARK: - Variables

    let radiusOptions = PlaceSettings.radiusOptions
    let soundModes = AlertSoundMode.allCases
    private(set) var notificationAuthorization: NotificationAuthorization?
    private(set) var homePlace: HomePlace?
    private(set) var soundMode: AlertSoundMode = .sound
    private(set) var isLiveActivityEnabled = true
    private(set) var isLiveActivityAllowedBySystem: Bool?
    private(set) var boundaries: [RegionBoundary] = []

    @ObservationIgnored
    private let router: SettingsRouterProtocol

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let alertSoundService: AlertSoundServiceProtocol

    @ObservationIgnored
    private let liveActivitySettingsService: LiveActivitySettingsServiceProtocol

    @ObservationIgnored
    private let notificationPermissionService: NotificationPermissionServiceProtocol

    @ObservationIgnored
    private let versionInfo: AppVersionInfo

    @ObservationIgnored
    private let feedbackEmail: String

    init(
        router: SettingsRouterProtocol,
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        alertSoundService: AlertSoundServiceProtocol,
        liveActivitySettingsService: LiveActivitySettingsServiceProtocol,
        notificationPermissionService: NotificationPermissionServiceProtocol,
        versionInfo: AppVersionInfo,
        feedbackEmail: String
    ) {
        self.router = router
        self.placeSettingsRepository = placeSettingsRepository
        self.regionBoundaryRepository = regionBoundaryRepository
        self.alertSoundService = alertSoundService
        self.liveActivitySettingsService = liveActivitySettingsService
        self.notificationPermissionService = notificationPermissionService
        self.versionInfo = versionInfo
        self.feedbackEmail = feedbackEmail
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        placeSettingsRepository.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.homePlace = settings.home
            }
            .store(in: &cancellables)

        alertSoundService.modePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.soundMode = mode
            }
            .store(in: &cancellables)

        liveActivitySettingsService.isEnabledPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.isLiveActivityEnabled = isEnabled
            }
            .store(in: &cancellables)
    }
}

// MARK: - SettingsViewModelProtocol

extension SettingsViewModel: SettingsViewModelProtocol {

    var home: SettingsHomeContent? {
        guard let homePlace else { return nil }
        let regionName = boundaries.first { $0.contains(homePlace.coordinate) }?.name
        return SettingsHomeContent(home: homePlace, regionName: regionName)
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
            // Only for the region under the home's address; without it the section still works.
            boundaries = (try? await regionBoundaryRepository.fetchBoundaries()) ?? []
        }
    }

    func didTapAllowNotifications() async {
        notificationAuthorization = await notificationPermissionService.requestAuthorization()
    }

    func didSelectHomeRadius(_ radiusKm: Double) {
        // Shown at once: the repository's update arrives a run loop later, and until then the picker would read the
        // old radius and jump back.
        if let homePlace {
            self.homePlace = HomePlace(coordinate: homePlace.coordinate, radiusKm: radiusKm, address: homePlace.address)
        }
        placeSettingsRepository.setRadius(radiusKm, for: .home)
    }

    func didTapPickHomeOnMap() {
        router.showHomePickerOnMap()
    }

    func didTapRemoveHome() {
        placeSettingsRepository.removeHome()
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

    func didTapPlaySample() {
        alertSoundService.playSample(of: soundMode)
    }
}

// MARK: - Constants

private enum Constants {
    static let mailtoScheme = "mailto"
}
