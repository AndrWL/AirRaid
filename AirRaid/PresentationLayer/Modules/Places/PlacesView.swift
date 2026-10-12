//
//  PlacesView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The user's watched places — their location and their home — with the radius around each: threats inside it show
/// up in the card over the map.
struct PlacesView<ViewModel: PlacesViewModelProtocol>: View {

    // MARK: - Variables

    private let viewModel: ViewModel
    private let onClose: () -> Void

    init(
        viewModel: ViewModel,
        onClose: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    var body: some View {
        List {
            header
            currentLocationSection
            homeSection
            footer
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .overlay(alignment: .topTrailing) { closeButton }
        .task { await viewModel.onAppear() }
    }
}

// MARK: - Sections

private extension PlacesView {

    var header: some View {
        Section {
            Text("Мої місця")
                .font(.app(.title2, weight: .bold))
                .foregroundStyle(.ink)
                .padding(.trailing, Constants.closeButtonClearance)
        }
        .listRowBackground(Color.surface)
    }

    var currentLocationSection: some View {
        Section {
            placeTitle(.currentLocation)
            if viewModel.locationAuthorization == .authorized {
                radiusPicker(selection: viewModel.currentLocationRadiusKm, for: .currentLocation)
            } else {
                hint("Дозвольте геолокацію кнопкою «до мене» на карті.")
            }
        }
        .listRowBackground(Color.surface)
    }

    var homeSection: some View {
        Section {
            placeTitle(.home, detail: viewModel.homeRegionName)
            if let homeRadiusKm = viewModel.homeRadiusKm {
                radiusPicker(selection: homeRadiusKm, for: .home)
                Button("Прибрати дім", role: .destructive, action: viewModel.didTapRemoveHome)
                    .font(.app(.body, weight: .semibold))
            } else {
                hint("Затисніть точку на карті, щоб позначити дім.")
            }
        }
        .listRowBackground(Color.surface)
    }

    var footer: some View {
        Section {
        } footer: {
            Text("Загрози в межах радіуса з'являються в картці на карті. Місця зберігаються лише на цьому пристрої.")
                .font(.app(.footnote))
                .foregroundStyle(.inkMuted)
        }
    }
}

// MARK: - Components

private extension PlacesView {

    func placeTitle(
        _ kind: WatchedPlaceKind,
        detail: String? = nil
    ) -> some View {
        HStack {
            Label(kind.title, systemImage: kind.systemImage)
                .font(.app(.body, weight: .semibold))
                .foregroundStyle(.ink)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.app(.footnote))
                    .foregroundStyle(.inkMuted)
            }
        }
    }

    func radiusPicker(
        selection: Double,
        for kind: WatchedPlaceKind
    ) -> some View {
        Picker(
            "Радіус",
            selection: Binding(
                get: { selection },
                set: { viewModel.didSelectRadius($0, for: kind) }
            )
        ) {
            ForEach(viewModel.radiusOptions, id: \.self) { radius in
                Text(DisplayTime.distance(radius)).tag(radius)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Радіус: \(kind.title)")
    }

    func hint(_ text: String) -> some View {
        Text(text)
            .font(.app(.footnote))
            .foregroundStyle(.inkMuted)
    }

    var closeButton: some View {
        CloseButton(action: onClose)
            .padding(Spacing.large)
    }
}

// MARK: - Constants

private enum Constants {
    /// Room on the right of the header for the close button overlay.
    static let closeButtonClearance: CGFloat = 36
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PlacesView(
                viewModel: PlacesViewModel(
                    placeSettingsRepository: PlaceSettingsRepository(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                    userLocationService: UserLocationService(),
                    regionBoundaryRepository: RegionBoundaryRepository()
                ),
                onClose: {}
            )
            .presentationDetents([.medium, .large])
        }
}
