//
//  RegionDetailsView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import SwiftUI

/// The state of one region: whether it is under an air raid alert and for how long, every official alert in it
/// (oblast, raions, hromadas), and the threats reported there.
struct RegionDetailsView<ViewModel: RegionDetailsViewModelProtocol>: View {

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
        // Durations change while the sheet is open.
        TimelineView(.periodic(from: .now, by: Constants.refreshInterval)) { timeline in
            if let content = viewModel.content(at: timeline.date) {
                details(content)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.appBackground)
        .overlay(alignment: .topTrailing) { closeButton }
        .task { await viewModel.onAppear() }
    }
}

// MARK: - Sections

private extension RegionDetailsView {

    func details(_ content: RegionDetailsContent) -> some View {
        List {
            header(content)
            // With no alerts the header's badge already says so.
            if !content.alerts.isEmpty {
                alertsSection(content)
            }
            if !content.threats.isEmpty {
                threatsSection(content)
            }
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
    }

    func header(_ content: RegionDetailsContent) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(content.title)
                    .font(.app(.title2, weight: .bold))
                    .foregroundStyle(.ink)
                    .padding(.trailing, Constants.closeButtonClearance)
                HStack(spacing: Spacing.small) {
                    Badge(content.status.title, tone: badgeTone(of: content.status))
                    if let durationText = content.durationText {
                        Text(durationText)
                            .font(.app(.callout))
                            .foregroundStyle(.inkMuted)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(Motion.quick, value: durationText)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            focusButton
        }
        .listRowBackground(Color.surface)
    }

    func alertsSection(_ content: RegionDetailsContent) -> some View {
        Section("Офіційні тривоги") {
            ForEach(content.alerts) { alert in
                RegionAlertRowView(alert)
            }
        }
        .listRowBackground(Color.surface)
    }

    func threatsSection(_ content: RegionDetailsContent) -> some View {
        Section("Загрози · \(content.threats.count)") {
            ForEach(content.threats) { threat in
                threatRow(threat)
            }
        }
        .listRowBackground(Color.surface)
    }
}

// MARK: - Components

private extension RegionDetailsView {

    func threatRow(_ threat: RegionDetailsContent.ThreatRow) -> some View {
        HStack(spacing: Constants.threatRowSpacing) {
            Image(threat.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.threatGlyphSize, height: Constants.threatGlyphSize)
                .foregroundStyle(.ink)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(threat.title)
                    .foregroundStyle(.ink)
                if let detail = threat.detail {
                    Text(detail)
                        .font(.app(.footnote))
                        .foregroundStyle(.inkMuted)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Focusing closes the sheet, so the region the camera moves to is not hidden behind it.
    var focusButton: some View {
        Button {
            let isEntering = !viewModel.isFocused
            viewModel.didTapFocus()
            if isEntering {
                onClose()
            }
        } label: {
            Label(
                viewModel.isFocused ? "Показати всю Україну" : "Лише ця область на карті",
                systemImage: viewModel.isFocused ? "arrow.up.left.and.arrow.down.right" : "scope"
            )
            .font(.app(.body, weight: .semibold))
        }
    }

    var closeButton: some View {
        CloseButton(action: onClose)
            .padding(Spacing.large)
    }

    func badgeTone(of status: RegionAlertStatus) -> Badge.Tone {
        switch status.level {
        case .red: return .alertRed
        case .yellow: return .alertYellow
        case nil: return .allClear
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let refreshInterval: TimeInterval = 15
    static let threatGlyphSize: CGFloat = 22
    static let threatRowSpacing: CGFloat = 12
    /// Room on the right of the header for the close button overlay.
    static let closeButtonClearance: CGFloat = 36
    /// Keeps previews from touching the app's own focus.
    static let previewDefaults = UserDefaults(suiteName: "preview") ?? .standard
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            RegionDetailsView(
                viewModel: RegionDetailsViewModel(
                    regionID: "UA-30",
                    airSituationRepository: DemoAirSituationRepository(),
                    regionBoundaryRepository: RegionBoundaryRepository(),
                    focusedRegionRepository: FocusedRegionRepository(defaults: Constants.previewDefaults)
                ),
                onClose: {}
            )
            .presentationDetents([.medium, .large])
        }
}
