//
//  AlertSoundServiceProtocol.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// Plays the app's alert sounds while it is open.
protocol AlertSoundServiceProtocol {

    /// A short alert that a threat has come within the radius of one of the user's places. Vibrates instead when the
    /// device is on silent.
    func playThreatNearby()
}
