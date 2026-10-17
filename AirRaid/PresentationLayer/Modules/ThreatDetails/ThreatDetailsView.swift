//
//  ThreatDetailsView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 09.10.2026.
//

import SwiftUI

/// The details of one threat: what it is, where it is and where it is heading, how fresh and how trusted
/// the report is, and the official alerts in its region.
///
/// Everything estimated is labelled as such: the app aggregates open sources and must not look more certain
/// than it is.
struct ThreatDetailsView<ViewModel: ThreatDetailsViewModelProtocol>: View {

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
        // Relative times and the time to the target change while the sheet is open.
        TimelineView(.periodic(from: .now, by: Constants.refreshInterval)) { timeline in
            if let content = viewModel.content(at: timeline.date) {
                details(content)
            } else {
                ContentUnavailableView(
                    "Ціль не знайдено",
                    systemImage: "scope",
                    description: Text("Її вже немає в поточній обстановці.")
                )
            }
        }
        .sheetCloseBar(action: onClose)
    }
}

// MARK: - Sections

private extension ThreatDetailsView {

    func details(_ content: ThreatDetailsContent) -> some View {
        List {
            header(content)
            if let staleNote = content.staleNote {
                Section {
                    InlineNote(staleNote, systemImage: "clock.badge.exclamationmark", tone: .warning)
                }
                .listRowBackground(Color.surface)
            }
            locationSection(content)
            movementSection(content)
            reportSection(content)
            if !content.isCountryWide {
                alertsSection(content)
            }
            disclaimer
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    func header(_ content: ThreatDetailsContent) -> some View {
        Section {
            HStack(spacing: Constants.headerSpacing) {
                Image(content.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.threatGlyphSize, height: Constants.threatGlyphSize)
                    .rotationEffect(.degrees(content.iconRotation))
                    .foregroundStyle(.ink)
                    .frame(width: Constants.threatBadgeSize, height: Constants.threatBadgeSize)
                    .background(.surfaceSunken, in: .circle)

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    HStack(alignment: .firstTextBaseline, spacing: Constants.countSpacing) {
                        Text(content.title)
                            .font(.app(.title2, weight: .bold))
                            .foregroundStyle(.ink)
                        if let countText = content.countText {
                            Text(countText)
                                .font(.app(.title3, weight: .semibold))
                                .foregroundStyle(.inkMuted)
                                .contentTransition(.numericText())
                                .animation(Motion.quick, value: countText)
                        }
                    }
                    confidenceBadge(content.confidence)
                }
            }
            if let summary = content.summary {
                Text(summary)
                    .font(.app(.callout))
                    .foregroundStyle(.inkMuted)
            }
        }
        .listRowBackground(Color.surface)
    }

    func locationSection(_ content: ThreatDetailsContent) -> some View {
        Section("Де") {
            if let positionName = content.positionName {
                LabeledContent("Зараз", value: positionName)
            }
            if let targetName = content.targetName {
                LabeledContent("Курсом на", value: targetName)
            }
            if let timeToTargetText = content.timeToTargetText {
                LabeledContent("До цілі") {
                    estimated(timeToTargetText)
                }
            }
            ForEach(content.proximityRows) { row in
                LabeledContent(row.distanceLabel) {
                    estimated(row.distanceText)
                }
                if let arrivalText = row.arrivalText {
                    LabeledContent(row.arrivalLabel) {
                        estimated(arrivalText)
                    }
                }
            }
            LabeledContent("Область", value: content.regionName)
            if let locationNote = content.locationNote {
                InlineNote(locationNote, systemImage: "exclamationmark.triangle", tone: .warning)
            }
            if let noAlertNote = content.noAlertNote {
                InlineNote(noAlertNote, systemImage: "questionmark.circle", tone: .warning)
            }
        }
        .listRowBackground(Color.surface)
    }

    @ViewBuilder
    func movementSection(_ content: ThreatDetailsContent) -> some View {
        if content.courseText != nil || content.approachText != nil || content.speedText != nil {
            Section("Рух") {
                if let courseText = content.courseText {
                    LabeledContent("Курс", value: courseText)
                }
                if let approachText = content.approachText {
                    LabeledContent("Заходить з", value: approachText)
                }
                if let speedText = content.speedText {
                    LabeledContent("Швидкість") {
                        if content.isSpeedEstimated {
                            estimated(speedText)
                        } else {
                            Text(speedText)
                        }
                    }
                }
            }
            .listRowBackground(Color.surface)
        }
    }

    func reportSection(_ content: ThreatDetailsContent) -> some View {
        Section("Повідомлення") {
            LabeledContent("Помічено", value: content.firstSeenText)
            LabeledContent("Оновлено", value: content.updatedText)
            LabeledContent("Джерела", value: content.sourcesText)
        }
        .listRowBackground(Color.surface)
    }

    func alertsSection(_ content: ThreatDetailsContent) -> some View {
        Section("Офіційні тривоги · \(content.regionName)") {
            if content.alerts.isEmpty {
                InlineNote("Тривоги немає", systemImage: "checkmark.shield", tone: .allClear)
            } else {
                ForEach(content.alerts) { alert in
                    RegionAlertRowView(alert)
                }
            }
        }
        .listRowBackground(Color.surface)
    }

    var disclaimer: some View {
        Section {
        } footer: {
            Text("Дані зібрано з відкритих каналів моніторингу; положення та прогноз орієнтовні. "
                + "Не замінює офіційний сигнал повітряної тривоги.")
                .font(.app(.footnote))
                .foregroundStyle(.inkMuted)
        }
    }
}

// MARK: - Components

private extension ThreatDetailsView {

    /// Confidence grows by fill, never by alert colours.
    func confidenceBadge(_ confidence: ThreatDetailsContent.Confidence) -> some View {
        let tone: Badge.Tone = switch confidence.level {
        case .low: .neutral
        case .medium: .accentSoft
        case .high: .accent
        }
        return Badge("Достовірність: \(confidence.label)", tone: tone)
    }

    /// A value computed by the app rather than reported, tagged so it is not read as a fact.
    func estimated(_ text: String) -> some View {
        HStack(spacing: Spacing.small) {
            Text(text)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(Motion.quick, value: text)
            Badge.estimated
        }
        .accessibilityElement(children: .combine)
    }


}

// MARK: - Constants

private enum Constants {
    static let refreshInterval: TimeInterval = 15
    static let headerSpacing: CGFloat = 14
    static let threatGlyphSize: CGFloat = 28
    static let threatBadgeSize: CGFloat = 52
    static let countSpacing: CGFloat = 6
    /// Room on the right of the header for the close button overlay.
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            ThreatDetailsView(
                viewModel: ThreatDetailsViewModel(
                    threatID: "shahed-1",
                    airSituationRepository: DemoAirSituationRepository(),
                    watchedPlacesProvider: WatchedPlacesService.preview
                ),
                onClose: {}
            )
            .presentationDetents([.medium, .large])
        }
}
