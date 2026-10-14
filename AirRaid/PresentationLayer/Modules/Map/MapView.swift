//
//  MapView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import SwiftUI

/// The primary user interface for the Map tab: a full-screen map of alerts and threats.
struct MapView<ViewModel: MapViewModelProtocol>: View {

    // MARK: - Variables

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    private let viewModel: ViewModel

    init(
        viewModel: ViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        // Ghosts of reliable threats move on between reports; the rest of the map updates only with the data.
        TimelineView(.periodic(from: .now, by: Constants.forecastRefreshInterval)) { timeline in
            AirRaidMapView(
                styleURL: viewModel.styleURL,
                boundaries: viewModel.boundaries,
                districts: viewModel.districts,
                cities: viewModel.cities,
                alertCoverage: viewModel.alertCoverage,
                threats: viewModel.threats,
                nearThreatIDs: viewModel.nearThreatIDs,
                selection: viewModel.selection,
                focusedRegionID: viewModel.focusedRegionID,
                recenterRequest: viewModel.recenterRequest,
                showsUserLocation: viewModel.locationAuthorization == .authorized,
                flyRequest: viewModel.flyRequest,
                isPickingLocation: viewModel.isPickingHome,
                places: viewModel.places,
                forecastDate: timeline.date,
                onSelect: viewModel.didSelect,
                onCenterChange: viewModel.didChangeMapCenter
            )
        }
        // Edge to edge: the tab bar floats at the top on iPad and at the bottom on iPhone.
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            VStack(spacing: Spacing.small) {
                if let notice = viewModel.connectionNotice {
                    MapConnectionBanner(notice: notice)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                }
                if let focusedRegionName = viewModel.focusedRegionName {
                    RegionFocusPill(
                        regionName: focusedRegionName,
                        onRecenter: viewModel.didTapRecenter,
                        onExit: viewModel.didTapExitFocus
                    )
                    .transition(.opacity)
                }
                if !viewModel.isPickingHome {
                    placeThreatBanners
                }
            }
            .padding(.top, Spacing.small)
        }
        .animation(Motion.resolved(Motion.bouncy, reduceMotion: reduceMotion), value: viewModel.connectionNotice)
        .animation(Motion.resolved(Motion.quick, reduceMotion: reduceMotion), value: viewModel.focusedRegionName)
        .overlay {
            if viewModel.isPickingHome {
                HomePickerOverlay(
                    isMovingHome: viewModel.placeSettings.home != nil,
                    onConfirm: viewModel.didConfirmHomePick,
                    onCancel: viewModel.didCancelHomePick
                )
            } else {
                bottomControls
            }
        }
        .animation(Motion.resolved(Motion.quick, reduceMotion: reduceMotion), value: viewModel.isPickingHome)
        .sensoryFeedback(.success, trigger: viewModel.placeSettings.home)
        .sensoryFeedback(.warning, trigger: viewModel.nearThreatAlertCount)
        .alert("Доступ до локації вимкнено", isPresented: locationDeniedAlert) {
            Button("Відкрити Налаштування") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Дозвольте AirRaid бачити локацію «під час використання», щоб показати вас на карті та відстань до загроз.")
        }
        .sensoryFeedback(.selection, trigger: viewModel.selection) { _, newValue in newValue != nil }
        .task { await viewModel.onAppear() }
    }
}

// MARK: - Private methods

private extension MapView {

    /// A banner per place with a threat inside its radius; distances and times move on between reports.
    var placeThreatBanners: some View {
        TimelineView(.periodic(from: .now, by: Constants.nearestThreatRefreshInterval)) { timeline in
            VStack(spacing: Spacing.small) {
                ForEach(viewModel.placeThreats(at: timeline.date)) { summary in
                    PlaceThreatBanner(summary: summary) {
                        viewModel.didSelect(.threat(id: summary.threatID))
                    }
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(Motion.resolved(Motion.bouncy, reduceMotion: reduceMotion), value: viewModel.placeThreats(at: timeline.date))
        }
    }

    /// The places and "to me" buttons on the right; above the map's attribution and the tab bar.
    var bottomControls: some View {
        VStack {
            Spacer()
            bottomControlsRow
        }
    }

    var bottomControlsRow: some View {
        HStack(alignment: .bottom, spacing: Spacing.small) {
            Spacer(minLength: 0)
            VStack(spacing: Spacing.small) {
                placesButton
                locateButton
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.bottom, Constants.bottomControlsInset)
    }

    var placesButton: some View {
        Button(action: viewModel.didTapPlaces) {
            Image(systemName: viewModel.placeSettings.home == nil ? "house" : "house.fill")
                .font(.app(.body, weight: .semibold))
                .foregroundStyle(WatchedPlaceKind.home.tint)
                .frame(width: Constants.locateButtonSize, height: Constants.locateButtonSize)
                .glassBackground(in: .circle)
                // The whole disc, not only the glyph: a tap on the glass edge would fall through to the map.
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Мої місця")
    }

    var locateButton: some View {
        Button(action: viewModel.didTapLocate) {
            Image(systemName: viewModel.locationAuthorization == .denied ? "location.slash" : "location.fill")
                .font(.app(.body, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: Constants.locateButtonSize, height: Constants.locateButtonSize)
                .glassBackground(in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Показати мене на карті")
    }

    /// The view model owns the flag; the alert only reports its dismissal.
    var locationDeniedAlert: Binding<Bool> {
        Binding(
            get: { viewModel.isLocationDeniedAlertPresented },
            set: { isPresented in
                if !isPresented { viewModel.didDismissLocationDeniedAlert() }
            }
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let nearestThreatRefreshInterval: TimeInterval = 15
    static let forecastRefreshInterval: TimeInterval = 5
    static let locateButtonSize: CGFloat = 48
    /// Clears the map's logo and attribution button at the bottom edge.
    static let bottomControlsInset: CGFloat = 40
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return Group {
        if let styleURL = URL(string: AppEnvironment.mapStyleURLString) {
            MapView(
                viewModel: MapViewModel(
                    router: MapRouter(stackRouter: StackRouter(), intentChannel: MapIntentChannel()),
                    regionBoundaryRepository: RegionBoundaryRepository(),
                    districtBoundaryRepository: DistrictBoundaryRepository(),
                    cityRepository: CityRepository(),
                    airSituationRepository: DemoAirSituationRepository(),
                    realtimeService: container.services.realtimeService,
                    focusedRegionRepository: container.repositories.focusedRegionRepository,
                    userLocationService: container.services.userLocationService,
                    placeSettingsRepository: container.repositories.placeSettingsRepository,
                    alertSoundService: container.services.alertSoundService,
                    styleURL: styleURL
                )
            )
        }
    }
}
