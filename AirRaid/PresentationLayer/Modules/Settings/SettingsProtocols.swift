//
//  SettingsProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// Defines the state of the Settings tab: the notification permission, the home, the Live Activity, the alert sound and
/// the app's version.
protocol SettingsViewModelProtocol: BaseViewModelProtocol {

    /// The notification permission, or `nil` until it has been read.
    var notificationAuthorization: NotificationAuthorization? { get }

    /// The home, or `nil` while none is set.
    var home: SettingsHomeContent? { get }

    /// The radii to pick from, in kilometres.
    var radiusOptions: [Double] { get }

    var soundModes: [AlertSoundMode] { get }

    var soundMode: AlertSoundMode { get }

    /// The user's choice for the Live Activity on the lock screen and in the Dynamic Island.
    var isLiveActivityEnabled: Bool { get }

    /// Whether iOS allows Live Activities for the app; `nil` until it has been read.
    var isLiveActivityAllowedBySystem: Bool? { get }

    /// «1.2 (34)».
    var appVersion: String { get }

    /// A `mailto:` link with the version and iOS in the body; `nil` if it could not be built.
    var feedbackURL: URL? { get }

    /// Reads the notification and Live Activity permissions again (the user may have changed them in the Settings app)
    /// and loads the outlines that name the home's region. Safe to call on every appearance.
    func onAppear() async

    /// Shows the system prompt; only does something while the user was never asked.
    func didTapAllowNotifications() async

    func didSelectHomeRadius(_ radiusKm: Double)

    /// Switches to the map with the home picker.
    func didTapPickHomeOnMap()

    func didTapRemoveHome()

    func didToggleLiveActivity(_ isEnabled: Bool)

    func didSelectSoundMode(_ mode: AlertSoundMode)

    /// Plays the selected mode's signal once.
    func didTapPlaySample()
}

/// Defines the routing capabilities for the Settings flow.
protocol SettingsRouterProtocol: BaseRouterProtocol {

    /// Opens the Map tab with the home picker.
    func showHomePickerOnMap()
}
