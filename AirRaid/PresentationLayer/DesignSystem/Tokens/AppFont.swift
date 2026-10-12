//
//  AppFont.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import CoreText
import SwiftUI
import UIKit

/// The app typeface: Manrope (SIL OFL), bundled as one variable font in `Resources/Fonts/`.
///
/// Sizes follow Dynamic Type: each text style maps to its size at the Large setting and scales with it.
/// The font is registered on first use, so previews get it without ``AppConfigurator``.
enum AppFont {

    /// The family name passed to `Font.custom`; the variable font picks the weight from `.weight(_:)`.
    static let familyName = "Manrope"

    /// Registers the bundled font files with the process. Safe to call more than once.
    static func register() {
        _ = registration
    }

    /// The point size of a text style at the default (Large) Dynamic Type setting.
    static func size(of style: Font.TextStyle) -> CGFloat {
        Constants.sizes[style] ?? Constants.bodySize
    }

    /// A UIKit font for appearance proxies (navigation and tab bars), scaled for Dynamic Type.
    static func uiFont(
        _ style: UIFont.TextStyle,
        size: CGFloat,
        weight: UIFont.Weight
    ) -> UIFont {
        register()
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: familyName,
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        let font = UIFont(descriptor: descriptor, size: size)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }
}

// MARK: - Font

extension Font {

    /// The app typeface at a Dynamic Type text style.
    ///
    /// ```swift
    /// Text(title).font(.app(.title2, weight: .bold))
    /// ```
    static func app(
        _ style: Font.TextStyle,
        weight: Font.Weight = .regular
    ) -> Font {
        AppFont.register()
        return .custom(AppFont.familyName, size: AppFont.size(of: style), relativeTo: style).weight(weight)
    }
}

// MARK: - Private methods

private extension AppFont {

    /// Runs once per process: a static `let` is initialised lazily and atomically.
    static let registration: Void = {
        let urls = Bundle.main.urls(forResourcesWithExtension: Constants.fontExtension, subdirectory: nil) ?? []
        guard !urls.isEmpty else {
            assertionFailure("[AppFont] No bundled .ttf files")
            return
        }
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already registered (a preview reload) is fine; anything else is a packaging bug.
                let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
                if code != Constants.alreadyRegisteredCode {
                    assertionFailure(
                        "[AppFont] Failed to register \(url.lastPathComponent): \(String(describing: code))"
                    )
                }
            }
        }
    }()
}

// MARK: - Constants

private enum Constants {
    static let fontExtension = "ttf"
    /// `kCTFontManagerErrorAlreadyRegistered`.
    static let alreadyRegisteredCode = 105
    static let bodySize: CGFloat = 17
    /// Apple's sizes at the Large setting; `relativeTo:` scales them for the other settings.
    static let sizes: [Font.TextStyle: CGFloat] = [
        .largeTitle: 34,
        .title: 28,
        .title2: 22,
        .title3: 20,
        .headline: 17,
        .body: 17,
        .callout: 16,
        .subheadline: 15,
        .footnote: 13,
        .caption: 12,
        .caption2: 11
    ]
}
