//
//  AlertSoundService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import AudioToolbox
import Combine
import Foundation

/// Plays a built-in system alert sound: no bundled audio, and the system handles silent mode by vibrating.
///
/// Keeps the user's ``AlertSoundMode`` in `UserDefaults`.
final class AlertSoundService {

    // MARK: - Variables

    private let defaults: UserDefaults
    private let subject: CurrentValueSubject<AlertSoundMode, Never>

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Constants.modeKey).flatMap(AlertSoundMode.init(rawValue:))
        self.subject = CurrentValueSubject(stored ?? .sound)
    }
}

// MARK: - AlertSoundServiceProtocol

extension AlertSoundService: AlertSoundServiceProtocol {

    var modePublisher: AnyPublisher<AlertSoundMode, Never> {
        subject.eraseToAnyPublisher()
    }

    func setMode(_ mode: AlertSoundMode) {
        guard mode != subject.value else { return }
        defaults.set(mode.rawValue, forKey: Constants.modeKey)
        subject.send(mode)
    }

    @discardableResult
    func playThreatNearby() -> Bool {
        play(subject.value)
    }

    func playSample(of mode: AlertSoundMode) {
        play(mode)
    }
}

// MARK: - Private methods

private extension AlertSoundService {

    @discardableResult
    func play(_ mode: AlertSoundMode) -> Bool {
        switch mode {
        case .sound:
            AudioServicesPlayAlertSound(Constants.threatNearbySound)
            return true
        case .vibration:
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return true
        case .off:
            return false
        }
    }
}

// MARK: - Constants

private enum Constants {
    /// The system's "alarm" sound.
    static let threatNearbySound: SystemSoundID = 1005
    static let modeKey = "alertSoundMode"
}
