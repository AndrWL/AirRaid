//
//  HomeStatusBroadcasting.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

/// Keeps the surfaces outside the app — the home screen widgets and the Live Activity — in step with the home's status.
protocol HomeStatusBroadcasting {

    /// Starts following the situation and the home. Idempotent; runs for the rest of the session.
    func start()
}
