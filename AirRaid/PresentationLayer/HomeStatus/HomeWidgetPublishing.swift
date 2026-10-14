//
//  HomeWidgetPublishing.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit

/// Hands the home's status to the home screen and lock screen widgets.
protocol HomeWidgetPublishing {

    /// Saves the snapshot for the widget extension and asks the widgets to redraw when what they show has changed.
    func publish(_ snapshot: HomeStatusSnapshot)
}
