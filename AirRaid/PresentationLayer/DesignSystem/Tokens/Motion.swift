//
//  Motion.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The animation curves of the design system.
///
/// Springy curves answer what the person did; changes of the air situation (a new alert, all clear) stay smooth.
/// With Reduce Motion every curve becomes a short cross-fade — see ``resolved(_:reduceMotion:)``.
enum Motion {

    /// Taps, badges, rolling digits, toggles.
    static let quick: Animation = .snappy(duration: 0.3)
    /// Content appearing or changing inside a sheet or a section.
    static let standard: Animation = .smooth(duration: 0.4)
    /// Only in response to the person: a selected pin, a banner sliding in.
    static let bouncy: Animation = .bouncy(duration: 0.5, extraBounce: 0.05)
    /// An oblast fill fading in on `alert_on`.
    static let mapAlertOnDuration: TimeInterval = 0.6
    /// An oblast fill fading out on `alert_off`: slower, like breathing out.
    static let mapAlertOffDuration: TimeInterval = 1.2
    /// What every curve becomes with Reduce Motion.
    static let reduced: Animation = .easeInOut(duration: 0.2)

    /// The curve to use given the person's Reduce Motion setting.
    ///
    /// Pair it with opacity-only transitions when `reduceMotion` is on.
    static func resolved(
        _ animation: Animation,
        reduceMotion: Bool
    ) -> Animation {
        reduceMotion ? reduced : animation
    }
}
