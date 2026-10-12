//
//  Radius.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import CoreGraphics

/// Corner radii of the design system (`radius-*` tokens).
///
/// Badges, banners and round buttons use `.capsule` / `.circle` shapes instead of a radius.
enum Radius {

    /// Tags inside a row, small plates.
    static let small: CGFloat = 6
    /// Notes and cards outside a `List`.
    static let medium: CGFloat = 12
    /// Large cards. Sheet corners are the system's.
    static let large: CGFloat = 20
}
