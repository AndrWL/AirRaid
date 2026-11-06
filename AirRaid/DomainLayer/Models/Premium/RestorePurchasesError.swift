//
//  RestorePurchasesError.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 16.10.2026.
//

import Foundation

/// Why "Restore purchases" ended without asking the App Store.
nonisolated enum RestorePurchasesError: Error, Equatable {

    /// The user closed the Apple Account sign-in; nothing went wrong, so nothing should be said.
    case cancelled
}
