//
//  FeedSheetRoute.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

/// Defines the sheets of the Feed tab.
enum FeedSheetRoute: Identifiable {

    /// AirRaid Плюс: what it adds and the subscription.
    case paywall

    /// The last night around the user's places.
    case nightReport

    var id: Self { self }
}
