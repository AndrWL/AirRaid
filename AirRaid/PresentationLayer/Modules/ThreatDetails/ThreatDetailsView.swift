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
        .overlay(alignment: .topTrailing) { closeButton }
    }
}

// MARK: - Sections

private extension ThreatDetailsView {

    func details(_ content: ThreatDetailsContent) -> some View {
        List {
            header(content)
            if let staleNote = content.staleNote {
                Section {
                    Label(staleNote, systemImage: "clock.badge.exclamationmark")
                        .foregroundStyle(.orange)
                }
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
    }

    func header(_ content: ThreatDetailsContent) -> some View {
        Section {
            HStack(spacing: 14) {
                Image(content.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(content.iconRotation))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(.quaternary, in: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(content.title)
                            .font(.title2.bold())
                        if let countText = content.countText {
                            Text(countText)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    confidenceBadge(content.confidence)
                }
                .padding(.trailing, 36)
            }
            if let summary = content.summary {
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
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
            LabeledContent("Область", value: content.regionName)
            if let locationNote = content.locationNote {
                Label(locationNote, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
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
        }
    }

    func reportSection(_ content: ThreatDetailsContent) -> some View {
        Section("Повідомлення") {
            LabeledContent("Помічено", value: content.firstSeenText)
            LabeledContent("Оновлено", value: content.updatedText)
            LabeledContent("Джерела", value: content.sourcesText)
        }
    }

    func alertsSection(_ content: ThreatDetailsContent) -> some View {
        Section("Офіційні тривоги · \(content.regionName)") {
            if content.alerts.isEmpty {
                Label("Тривоги немає", systemImage: "checkmark.shield")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(content.alerts) { alert in
                    alertRow(alert)
                }
            }
        }
    }

    var disclaimer: some View {
        Section {
        } footer: {
            Text("Дані зібрано з відкритих каналів моніторингу, положення та прогноз — орієнтовні. "
                + "Не замінює офіційний сигнал повітряної тривоги.")
        }
    }
}

// MARK: - Components

private extension ThreatDetailsView {

    func confidenceBadge(_ confidence: ThreatDetailsContent.Confidence) -> some View {
        Text("Достовірність: \(confidence.label) · \(confidence.percentText)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color(of: confidence.level))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color(of: confidence.level).opacity(0.15), in: .capsule)
    }

    func alertRow(_ alert: ThreatDetailsContent.AlertRow) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(alert.level.map { color(of: $0) } ?? .secondary)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.name)
                if let kindText = alert.kindText {
                    Text(kindText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(alert.startedText)
                Text(alert.durationText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// A value computed by the app rather than reported, tagged so it is not read as a fact.
    func estimated(_ text: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
            Text("оцінка")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: .capsule)
        }
    }

    var closeButton: some View {
        Button("Закрити", systemImage: "xmark", action: onClose)
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .closeButtonStyle()
            .buttonBorderShape(.circle)
            .padding()
    }

    func color(of level: ThreatLevel) -> Color {
        switch level {
        case .low: return .gray
        case .medium: return .yellow
        case .high: return .green
        }
    }

    func color(of level: RegionAlertLevel) -> Color {
        switch level {
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}

// MARK: - View

private extension View {

    /// Liquid Glass on iOS 26, a plain bordered circle before it.
    @ViewBuilder
    func closeButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let refreshInterval: TimeInterval = 15
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            ThreatDetailsView(
                viewModel: ThreatDetailsViewModel(
                    threatID: "shahed-1",
                    airSituationRepository: DemoAirSituationRepository()
                ),
                onClose: {}
            )
            .presentationDetents([.medium, .large])
        }
}
