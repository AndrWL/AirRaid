//
//  NightReportView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The night report: how long the alert lasted and what flew around the user's places last night.
struct NightReportView<ViewModel: NightReportViewModelProtocol>: View {

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
        ScrollView {
            if let content = viewModel.content {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    header(content)
                    alertSection(content)
                    threatsSection(content)
                    Text("За даними моніторингу, які AirRaid бачив на цьому пристрої. Поки застосунок закритий, ефір не збирається.")
                        .font(.app(.footnote))
                        .foregroundStyle(.inkMuted)
                }
                .padding(Spacing.large)
                .padding(.top, Spacing.xLarge)
            }
        }
        .background(Color.appBackground)
        .overlay(alignment: .topTrailing) {
            CloseButton(action: onClose)
                .padding(Spacing.large)
        }
    }
}

// MARK: - Sections

private extension NightReportView {

    func header(_ content: NightReportContent) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(content.title)
                .font(.app(.title, weight: .bold))
                .foregroundStyle(.ink)
            Text(content.periodText)
                .font(.app(.subheadline))
                .foregroundStyle(.inkMuted)
            Button(action: viewModel.didTapListen) {
                Label(
                    viewModel.isSpeaking ? "Зупинити" : "Прослухати",
                    systemImage: viewModel.isSpeaking ? "stop.fill" : "play.fill"
                )
                .font(.app(.body, weight: .semibold))
            }
            .glassButtonStyle()
            .padding(.top, Spacing.small)
        }
    }

    func alertSection(_ content: NightReportContent) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Тривога у ваших областях")
                .font(.app(.headline, weight: .semibold))
                .foregroundStyle(.ink)
            if !content.hasPlaces {
                InlineNote("Позначте дім, щоб бачити свою область", systemImage: "house", tone: .warning)
            } else if let alertDurationText = content.alertDurationText {
                HStack(alignment: .firstTextBaseline) {
                    Text(alertDurationText)
                        .font(.app(.title2, weight: .bold))
                        .foregroundStyle(.alertRedInk)
                    let declarations = FeedText.plural(content.alertCount, one: "оголошення", few: "оголошення", many: "оголошень")
                    Text("· \(content.alertCount) \(declarations)")
                        .font(.app(.subheadline))
                        .foregroundStyle(.inkMuted)
                }
            } else {
                InlineNote("Тривоги не було", systemImage: "checkmark.shield", tone: .allClear)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: Radius.large))
    }

    func threatsSection(_ content: NightReportContent) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Що летіло поруч")
                .font(.app(.headline, weight: .semibold))
                .foregroundStyle(.ink)
            if content.nearbyThreats.isEmpty {
                Text("Нічого у ваших областях")
                    .font(.app(.subheadline))
                    .foregroundStyle(.inkMuted)
            }
            ForEach(content.nearbyThreats) { threat in
                HStack(spacing: Spacing.small) {
                    Image(threat.iconName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(.ink)
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                        .accessibilityHidden(true)
                    Text(threat.title)
                        .font(.app(.body))
                        .foregroundStyle(.ink)
                    Spacer()
                    Text("\(threat.count)")
                        .font(.app(.body, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.ink)
                }
                .accessibilityElement(children: .combine)
            }
            Divider()
            LabeledContent("По всій країні", value: "\(content.countryThreatCount)")
                .font(.app(.subheadline))
                .foregroundStyle(.inkMuted)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: Radius.large))
    }
}

// MARK: - Constants

private enum Constants {
    static let iconSize: CGFloat = 24
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return NightReportCoordinatorView(appContainer: container)
}
