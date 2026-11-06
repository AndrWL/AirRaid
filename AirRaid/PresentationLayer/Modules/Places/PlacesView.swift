//
//  PlacesView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The user's watched places — their location, their home and, with Plus, their other places — with the radius around
/// each: threats inside it show up in the card over the map.
struct PlacesView<ViewModel: PlacesViewModelProtocol>: View {

    // MARK: - Variables

    @State private var isRemoveHomeConfirmationPresented = false
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
            customPlacesSections
            removeHomeSection
            footer
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .sheetCloseBar(action: onClose)
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
        }
        .listRowBackground(Color.surface)
    }

    var currentLocationSection: some View {
        Section {
            placeTitle(.currentLocation)
            if viewModel.locationAuthorization == .authorized {
                radiusPicker(selection: viewModel.currentLocationRadiusKm, title: WatchedPlaceKind.currentLocation.title) {
                    viewModel.didSelectCurrentLocationRadius($0)
                }
            } else {
                hint("Дозвольте доступ до геолокації кнопкою зі стрілкою на мапі.")
            }
        }
        .listRowBackground(Color.surface)
    }

    var homeSection: some View {
        Section {
            placeTitle(.home, detail: viewModel.homeRegionName)
            if let homeRadiusKm = viewModel.homeRadiusKm, let homeID = viewModel.homeID {
                radiusPicker(selection: homeRadiusKm, title: WatchedPlaceKind.home.title) {
                    viewModel.didSelectRadius($0, forPlace: homeID)
                }
            }
            homeActions
        }
        .listRowBackground(Color.surface)
    }

    /// Last and on its own, so a list that shifts under the finger cannot turn a tap on a home action into a removal.
    @ViewBuilder
    var removeHomeSection: some View {
        if viewModel.homeRadiusKm != nil {
            Section {
                Button("Прибрати дім", role: .destructive) {
                    isRemoveHomeConfirmationPresented = true
                }
                .font(.app(.body, weight: .semibold))
                // On the button, so the popover points at it.
                .confirmationDialog(
                    "Прибрати дім?",
                    isPresented: $isRemoveHomeConfirmationPresented,
                    titleVisibility: .visible
                ) {
                    Button("Прибрати", role: .destructive, action: viewModel.didTapRemoveHome)
                } message: {
                    Text("AirRaid перестане стежити за загрозами в радіусі дому.")
                }
            }
            .listRowBackground(Color.surface)
        }
    }

    var customPlacesSections: some View {
        ForEach(viewModel.customPlaces) { place in
            Section {
                placeTitle(.custom, title: place.title)
                radiusPicker(selection: place.radiusKm, title: place.title) {
                    viewModel.didSelectRadius($0, forPlace: place.id)
                }
            }
            .listRowBackground(Color.surface)
        }
    }

    var footer: some View {
        Section {
        } footer: {
            Text(
                "Загрози в межах радіуса з'являються в картці на мапі. Додати, перейменувати чи прибрати місця "
                    + "можна в Налаштуваннях. Місця зберігаються лише на цьому пристрої."
            )
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
                Label(viewModel.homeRadiusKm == nil ? "Обрати на мапі" : "Змінити на мапі", systemImage: "mappin.and.ellipse")
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
        title: String? = nil,
        detail: String? = nil
    ) -> some View {
        HStack {
            Label {
                Text(title ?? kind.title)
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
        title: String,
        onSelect: @escaping (Double) -> Void
    ) -> some View {
        Picker(
            "Радіус",
            selection: Binding(
                get: { selection },
                set: onSelect
            )
        ) {
            ForEach(viewModel.radiusOptions, id: \.self) { radius in
                Text(DisplayTime.distance(radius)).tag(radius)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Радіус: \(title)")
    }

    func hint(_ text: String) -> some View {
        Text(text)
            .font(.app(.footnote))
            .foregroundStyle(.inkMuted)
    }

}

// MARK: - Constants

private enum Constants {
    /// Room on the right of the header for the close button overlay.
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PlacesView(
                viewModel: PlacesViewModel(
                    placeSettingsRepository: PlaceSettingsRepository(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                    userLocationService: UserLocationService(),
                    regionBoundaryRepository: RegionBoundaryRepository(),
                    entitlementService: StoreKitEntitlementService(productIDs: [])
                ),
                onPickHomeOnMap: {},
                onClose: {}
            )
            .presentationDetents([.medium, .large])
        }
}
