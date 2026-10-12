//
//  Spacing.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import CoreGraphics

/// The spacing scale of the design system (`space-*` tokens).
///
/// Every padding and stack spacing comes from here, so screens line up without per-view numbers.
enum Spacing {

    /// Between the lines of a title + subtitle stack.
    static let xxSmall: CGFloat = 2
    /// Between a title and its badge; vertical badge padding.
    static let xSmall: CGFloat = 4
    /// Horizontal badge padding; between a value and its «оцінка» tag; from the safe area to a banner.
    static let small: CGFloat = 8
    /// Between a glyph and its text in a row or a banner.
    static let medium: CGFloat = 12
    /// Screen and banner side margins; the standard `.padding()`.
    static let large: CGFloat = 16
    /// Between groups of content outside a `List`.
    static let xLarge: CGFloat = 24
    /// Large empty states.
    static let xxLarge: CGFloat = 32
}
