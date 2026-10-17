//
//  SettingsProtocols.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// Defines the state of the Settings tab: the notification permission, the places, the Live Activity, the alert sound
/// and the app's version.
protocol SettingsViewModelProtocol: BaseViewModelProtocol {

    /// The notification permission, or `nil` until it has been read.
    var notificationAuthorization: NotificationAuthorization? { get }

    /// The saved places: the home first, then the custom ones.
    var places: [SettingsPlaceContent] { get }

    var hasHome: Bool { get }

    var isPlusActive: Bool { get }

    /// «2 з 10» — how many saved places Плюс allows; `nil` without Плюс.
    var placeCountText: String? { get }

    /// With Плюс at ``PremiumLimits/plusPlaces`` saved places, so no more can be added.
    var isAtPlaceLimit: Bool { get }

    var soundModes: [AlertSoundMode] { get }

    var mapStylePreferences: [MapStylePreference] { get }

    /// The base map's look.
    var mapStylePreference: MapStylePreference { get }

    var soundMode: AlertSoundMode { get }

    /// The user's choice for the Live Activity on the lock screen and in the Dynamic Island.
    var isLiveActivityEnabled: Bool { get }

    /// Whether iOS allows Live Activities for the app; `nil` until it has been read.
    var isLiveActivityAllowedBySystem: Bool? { get }

    /// «1.2 (34)».
    var appVersion: String { get }

    /// Set while the server refuses this version, for the note under it; `nil` otherwise.
    var upgradeNotice: UpgradeNotice? { get }

    /// A `mailto:` link with the version and iOS in the body; `nil` if it could not be built.
    var feedbackURL: URL? { get }

    /// The address behind ``feedbackURL``, offered to copy when no mail app can open the link.
    var feedbackEmail: String { get }

    /// Reads the notification and Live Activity permissions again (the user may have changed them in the Settings app)
    /// and loads the outlines that name the places' regions. Safe to call on every appearance.
    func onAppear() async

    /// Shows the system prompt; only does something while the user was never asked.
    func didTapAllowNotifications() async

    /// Switches to the map with the home picker.
    func didTapPickHomeOnMap()

    /// Switches to the map to add a place with Плюс, or opens the paywall without it.
    func didTapAddPlace()

    /// Opens the place's own screen: name, radius, moving and removing it.
    func didTapPlace(_ id: SavedPlace.ID)

    func didToggleLiveActivity(_ isEnabled: Bool)

    func didSelectSoundMode(_ mode: AlertSoundMode)

    func didSelectMapStyle(_ preference: MapStylePreference)

    /// Plays the selected mode's signal once.
    func didTapPlaySample()

    /// Opens the voice feed's settings.
    func didTapVoiceSettings()

    /// Opens AirRaid Плюс: the subscription, or its status for a subscriber.
    func didTapPlus()
}

/// Defines the routing capabilities for the Settings flow.
protocol SettingsRouterProtocol: BaseRouterProtocol, SheetPresenting where SheetRoute == SettingsSheetRoute {

    /// Opens the Map tab with the place picker.
    func showPlacePickerOnMap(_ pick: PlacePick)

    func showPlace(_ id: SavedPlace.ID)

    func showVoiceSettings()
}

/// A protocol that defines the requirements for a Settings flow factory.
protocol SettingsFactoryProtocol {

    associatedtype NavigationDestination: View
    associatedtype Sheet: View

    @ViewBuilder func navigationDestination(for route: SettingsRoute) -> NavigationDestination
    @ViewBuilder func sheet(for route: SettingsSheetRoute) -> Sheet
}
