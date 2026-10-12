//
//  FavoriteRegionsBar.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The followed regions as a row of chips over the map, each with its alert state; a tap opens the region.
struct FavoriteRegionsBar: View {

    // MARK: - Variables

    let chips: [FavoriteRegionChip]

    /// The region whose sheet is open, drawn as pressed.
    let selectedRegionID: String?

    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.small) {
                ForEach(chips) { chip in
                    chipButton(chip)
                }
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.xSmall)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Private methods

private extension FavoriteRegionsBar {

    func chipButton(_ chip: FavoriteRegionChip) -> some View {
        Button {
            onSelect(chip.id)
        } label: {
            HStack(spacing: Spacing.small) {
                StatusDot(dotTone(of: chip.status))
                Text(chip.name)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(.ink)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .glassBackground(in: .capsule)
            .overlay {
                if chip.id == selectedRegionID {
                    Capsule().strokeBorder(Color.accentColor, lineWidth: Constants.selectedBorderWidth)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(chip.name), \(chip.status.title)")
        .accessibilityAddTraits(chip.id == selectedRegionID ? .isSelected : [])
    }

    func dotTone(of status: RegionAlertStatus) -> StatusDot.Tone {
        switch status.level {
        case .red: return .alertRed
        case .yellow: return .alertYellow
        case nil: return .allClear
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let selectedBorderWidth: CGFloat = 1.5
}

#Preview {
    FavoriteRegionsBar(
        chips: [
            FavoriteRegionChip(region: RegionBoundary(id: "UA-30", name: "Київ", polygons: []), coverage: .none),
            FavoriteRegionChip(
                region: RegionBoundary(id: "UA-53", name: "Полтавська область", polygons: []),
                coverage: AirRaidCoverage(regions: ["UA-53": .red], districts: [:])
            ),
            FavoriteRegionChip(
                region: RegionBoundary(id: "UA-43", name: "Автономна Республіка Крим", polygons: []),
                coverage: AirRaidCoverage(regions: ["UA-43": .yellow], districts: [:])
            )
        ],
        selectedRegionID: "UA-53",
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(.black)
    .preferredColorScheme(.dark)
}
