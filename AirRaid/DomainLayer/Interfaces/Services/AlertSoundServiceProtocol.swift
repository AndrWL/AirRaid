//
//  AlertSoundServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Combine

/// Plays the app's alert sounds while it is open, the way the user chose in the settings.
protocol AlertSoundServiceProtocol {

    /// Emits the current mode on subscription and every change after it.
    var modePublisher: AnyPublisher<AlertSoundMode, Never> { get }

    /// Keeps the mode across launches.
    func setMode(_ mode: AlertSoundMode)

    /// Signals that a threat has come within the radius of one of the user's places, in the chosen mode.
    ///
    /// - Returns: Whether anything was played, so a haptic can follow; `false` when the mode is ``AlertSoundMode/off``.
    @discardableResult
    func playThreatNearby() -> Bool

    /// Plays the given mode's signal once, so the user can hear what it sounds like.
    func playSample(of mode: AlertSoundMode)
}
