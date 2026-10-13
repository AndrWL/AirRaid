//
//  AlertSoundService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import AudioToolbox

/// Plays a built-in system alert sound: no bundled audio, and the system handles silent mode by vibrating.
struct AlertSoundService {

}

// MARK: - AlertSoundServiceProtocol

extension AlertSoundService: AlertSoundServiceProtocol {

    func playThreatNearby() {
        AudioServicesPlayAlertSound(Constants.threatNearbySound)
    }
}

// MARK: - Constants

private enum Constants {
    /// The system's "alarm" sound.
    static let threatNearbySound: SystemSoundID = 1005
}
