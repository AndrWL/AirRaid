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
    private let onPickHomeOnMap: () -> Void
    private let onClose: () -> Void

    init(
        viewModel: ViewModel,
        onPickHomeOnMap: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onPickHomeOnMap = onPickHomeOnMap
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
            }
            homeActions
            if viewModel.homeRadiusKm != nil {
                Button("Прибрати дім", role: .destructive, action: viewModel.didTapRemoveHome)
                    .font(.app(.body, weight: .semibold))
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

    /// Where to put the home: on the map, or right where the user is.
    var homeActions: some View {
        Group {
            Button(action: onPickHomeOnMap) {
                Label(viewModel.homeRadiusKm == nil ? "Обрати на карті" : "Змінити на карті", systemImage: "mappin.and.ellipse")
            }
            if viewModel.canUseCurrentLocation {
                Button(action: viewModel.didTapUseCurrentLocation) {
                    Label("Дім там, де я зараз", systemImage: "location")
                }
            }
        }
        .font(.app(.body, weight: .semibold))
    }

    func placeTitle(
        _ kind: WatchedPlaceKind,
        detail: String? = nil
    ) -> some View {
        HStack {
            Label {
                Text(kind.title)
                    .foregroundStyle(.ink)
            } icon: {
                Image(systemName: kind.systemImage)
                    .foregroundStyle(kind.tint)
            }
            .font(.app(.body, weight: .semibold))
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
                onPickHomeOnMap: {},
                onClose: {}
            )
            .presentationDetents([.medium, .large])
        }
}
