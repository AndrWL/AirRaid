//
//  AlertSoundMode.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// How the app signals a threat coming within a radius while it is open.
nonisolated enum AlertSoundMode: String, CaseIterable, Sendable {

    /// The alert sound; the system vibrates instead when the device is on silent.
    case sound

    /// Only a vibration, even with the sound on.
    case vibration

    /// No sound and no vibration: the threat is only highlighted on the map.
    case off
}
