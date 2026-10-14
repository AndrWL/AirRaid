//
//  AirRaidWidgetsBundle.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI
import WidgetKit

/// The extension's entry point: the home status widget and the air raid Live Activity.
///
/// Everything shown is computed by the app (`HomeStatusKit`); the extension has no network access and no logic of its
/// own beyond formatting times. The design system's tokens, colours, font and threat silhouettes are shared with the
/// app target through the project file, not copied.
@main
struct AirRaidWidgetsBundle: WidgetBundle {

    var body: some Widget {
        HomeStatusWidget()
        HomeAlertLiveActivity()
    }
}
