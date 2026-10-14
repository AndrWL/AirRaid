//
//  HomeAlertLiveActivity.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI
import UIKit
import WidgetKit

/// The air raid at the home (or the user's location) on the lock screen and in the Dynamic Island: since when it lasts,
/// the nearest threat and when the forecast puts it over the place.
struct HomeAlertLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HomeAlertActivityAttributes.self) { context in
            HomeAlertLockScreenView(
                placeKind: context.attributes.placeKind,
                placeName: context.attributes.placeName,
                state: context.state,
                isStale: context.isStale
            )
            // The lock screen resolves the tint and the content in different schemes (light glass under white text on
            // iOS 26), so both are pinned to the dark scheme: the activity reads the same on every wallpaper.
            .environment(\.colorScheme, .dark)
            .activityBackgroundTint(Self.darkSurface)
            .activitySystemActionForegroundColor(Color.ink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HomeAlertIslandViews.title(context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HomeAlertIslandViews.duration(context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HomeAlertIslandViews.details(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                HomeAlertIslandViews.glyph(context.state)
            } compactTrailing: {
                HomeAlertIslandViews.compactText(context.state)
            } minimal: {
                HomeAlertIslandViews.glyph(context.state)
            }
            .keylineTint(context.state.color)
        }
    }

    /// ``Color/surface`` in its dark variant, resolved here because the system resolves the tint on its own.
    private static let darkSurface = Color(uiColor: .surface.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
}
