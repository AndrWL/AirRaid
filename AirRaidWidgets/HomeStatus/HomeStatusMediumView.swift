//
//  HomeStatusMediumView.swift
//  AirRaidWidgets
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import HomeStatusKit
import SwiftUI

/// The small widget's content next to a mini-map of the home's oblast.
struct HomeStatusMediumView: View {

    // MARK: - Variables

    let home: HomeStatus
    let entry: HomeStatusEntry

    var body: some View {
        HStack(spacing: Spacing.medium) {
            HomeStatusSmallView(home: home, entry: entry)
            if let miniMap = home.miniMap {
                MiniMapView(map: miniMap)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
