//
//  MapLegendCoordinatorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The coordinator view for the map legend sheet.
///
/// A static leaf: no navigation and no data of its own, so neither a router nor a view model. Closing is the
/// presenting sheet's dismissal, which also clears the Map router's `activeSheet` through the `.sheet(item:)` binding.
struct MapLegendCoordinatorView: View {

    // MARK: - Variables

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        MapLegendView {
            dismiss()
        }
    }
}

#Preview {
    MapLegendCoordinatorView()
}
