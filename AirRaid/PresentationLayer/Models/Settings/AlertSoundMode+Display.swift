//
//  AlertSoundMode+Display.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

extension AlertSoundMode {

    var title: String {
        switch self {
        case .sound: "Звук"
        case .vibration: "Лише вібрація"
        case .off: "Вимкнено"
        }
    }

    var systemImage: String {
        switch self {
        case .sound: "speaker.wave.2"
        case .vibration: "iphone.radiowaves.left.and.right"
        case .off: "speaker.slash"
        }
    }
}
