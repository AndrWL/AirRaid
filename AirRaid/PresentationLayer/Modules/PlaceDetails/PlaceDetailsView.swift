//
//  PlaceDetailsView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import SwiftUI

/// A saved place: where it is, whether there is an air raid alert right there, the threats inside its radius, and the
/// radius itself. Opened by a tap on the place's pin.
struct PlaceDetailsView<ViewModel: PlaceDetailsViewModelProtocol>: View {

    // MARK: - Variables

    @State private var isRemoveConfirmationPresented = false
    private let viewModel: ViewModel
    private let onMove: () -> Void
    private let onSelectThreat: (String) -> Void
    private let onClose: () -> Void

    init(
        viewModel: ViewModel,
        onMove: @escaping () -> Void,
        onSelectThreat: @escaping (String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onMove = onMove
        self.onSelectThreat = onSelectThreat
        self.onClose = onClose
    }

    var body: some View {
        // Distances and times change while the sheet is open.
        TimelineView(.periodic(from: .now, by: Constants.refreshInterval)) { timeline in
            if let content = viewModel.content(at: timeline.date) {
                details(content)
            } else {
                ContentUnavailableView("Місце прибрано", systemImage: "mappin.slash")
            }
        }
        .background(Color.appBackground)
        .sheetCloseBar(action: onClose)
        .task { await viewModel.onAppear() }
    }
}

// MARK: - Sections

private extension PlaceDetailsView {

    func details(_ content: PlaceDetailsContent) -> some View {
        List {
            header(content)
            threatsSection(content)
            radiusSection(content)
            actionsSection(content)
            removeSection(content)
            footer
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
    }

    func header(_ content: PlaceDetailsContent) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label {
                    Text(content.title)
                        .font(.app(.title2, weight: .bold))
                        .foregroundStyle(.ink)
                } icon: {
                    Image(systemName: content.kind.systemImage)
                        .foregroundStyle(content.kind.tint)
                }
                if let street = content.street {
                    Text(street)
                        .font(.app(.callout))
                        .foregroundStyle(.ink)
                }
                if let placeLine = content.placeLine {
                    Text(placeLine)
                        .font(.app(.footnote))
                        .foregroundStyle(.inkMuted)
                }
                Badge(content.alertTitle, tone: badgeTone(of: content.alertLevel))
            }
            .accessibilityElement(children: .combine)
        }
        .listRowBackground(Color.surface)
    }

    func threatsSection(_ content: PlaceDetailsContent) -> some View {
        Section {
            if content.threats.isEmpty {
                InlineNote("Поруч загроз немає", systemImage: "checkmark.shield", tone: .allClear)
            } else {
                ForEach(content.threats) { threat in
                    Button {
                        onSelectThreat(threat.id)
                    } label: {
                        threatRow(threat)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            // One text whose number changes in place, rather than a new header for every radius.
            Text("Загрози в радіусі \(DisplayTime.distance(viewModel.radiusKm ?? content.radiusKm))")
                .contentTransition(.numericText())
                .animation(Motion.quick, value: viewModel.radiusKm)
        }
        .listRowBackground(Color.surface)
    }

    /// Reads the radius from the view model, not from the timed content, so a tap is not undone by a stale snapshot.
    func radiusSection(_ content: PlaceDetailsContent) -> some View {
        Section("Радіус") {
            Picker(
                "Радіус",
                selection: Binding(
                    get: { viewModel.radiusKm ?? content.radiusKm },
                    set: { viewModel.didSelectRadius($0) }
                )
            ) {
                ForEach(viewModel.radiusOptions, id: \.self) { radius in
                    Text(DisplayTime.distance(radius)).tag(radius)
                }
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(Color.surface)
    }

    func actionsSection(_ content: PlaceDetailsContent) -> some View {
        Section {
            Button(action: onMove) {
                Label("Змінити на мапі", systemImage: "mappin.and.ellipse")
            }
        }
        .font(.app(.body, weight: .semibold))
        .listRowBackground(Color.surface)
    }

    /// Apart from the other actions and confirmed first, as in the place editor: the radius and address go with it.
    func removeSection(_ content: PlaceDetailsContent) -> some View {
        Section {
            Button(content.kind == .home ? "Прибрати дім" : "Прибрати місце", role: .destructive) {
                isRemoveConfirmationPresented = true
            }
            // On the button, so the popover points at it.
            .confirmationDialog(
                content.kind == .home ? "Прибрати дім?" : "Прибрати «\(content.title)»?",
                isPresented: $isRemoveConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Прибрати", role: .destructive) {
                    viewModel.didTapRemove()
                    onClose()
                }
            } message: {
                Text("AirRaid перестане стежити за загрозами в радіусі цього місця.")
            }
        }
        .font(.app(.body, weight: .semibold))
        .listRowBackground(Color.surface)
    }

    var footer: some View {
        Section {
        } footer: {
            Text("Адресу визначає Apple за координатами місця. Самі місця зберігаються лише на цьому пристрої.")
                .font(.app(.footnote))
                .foregroundStyle(.inkMuted)
        }
    }
}

// MARK: - Components

private extension PlaceDetailsView {

    func threatRow(_ threat: PlaceDetailsContent.ThreatRow) -> some View {
        HStack(spacing: Constants.threatRowSpacing) {
            Image(threat.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.threatGlyphSize, height: Constants.threatGlyphSize)
                .foregroundStyle(.alertRed)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(threat.title)
                    .foregroundStyle(.ink)
                Text(threat.detail)
                    .font(.app(.footnote))
                    .foregroundStyle(.inkMuted)
                    .monospacedDigit()
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.app(.footnote, weight: .semibold))
                .foregroundStyle(.inkMuted)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }


    func badgeTone(of level: RegionAlertLevel?) -> Badge.Tone {
        switch level {
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
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PlaceDetailsView(
                viewModel: PlaceDetailsViewModel(
                    placeID: UUID(),
                    placeSettingsRepository: PlaceSettingsRepository(defaults: UserDefaults(suiteName: "preview") ?? .standard),
                    airSituationRepository: DemoAirSituationRepository(),
                    regionBoundaryRepository: RegionBoundaryRepository(),
                    districtBoundaryRepository: DistrictBoundaryRepository()
                ),
                onMove: {},
                onSelectThreat: { _ in },
                onClose: {}
            )
            .presentationDetents([.medium, .large])
        }
}
