//
//  FeedView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// The Feed tab: the air situation as a chat of the monitoring channels, newest at the bottom.
struct FeedView<ViewModel: FeedViewModelProtocol>: View {

    // MARK: - Variables

    private let viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    if viewModel.hiddenHistoryCount > 0 {
                        historyUpsell
                    }
                    // «Поки тихо» would be wrong while no data arrives; the update banner says why it is empty.
                    if viewModel.rows.isEmpty, viewModel.upgradeNotice == nil {
                        emptyState
                    }
                    ForEach(viewModel.rows) { row in
                        if row.id == viewModel.firstUnreadID {
                            unreadDivider
                        }
                        FeedBubbleView(row: row) {
                            viewModel.didTapReadAloud(id: row.id)
                        }
                        .id(row.id)
                        .onTapGesture {
                            viewModel.didTapRow(id: row.id)
                        }
                        .accessibilityAddTraits(row.isOpenableOnMap ? .isButton : [])
                        .accessibilityHint(row.isOpenableOnMap ? "Показати на мапі" : "")
                    }
                }
                .padding(.horizontal, Spacing.large)
                .padding(.vertical, Spacing.medium)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: viewModel.rows.last?.id) { _, lastID in
                guard let lastID else { return }
                withAnimation(.easeOut) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .background(Color.appBackground)
        .navigationTitle("Ефір")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: viewModel.didTapNightReport) {
                    Label("Нічний звіт", systemImage: "moon.stars")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                voiceButton
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}

// MARK: - Sections

private extension FeedView {

    var header: some View {
        VStack(spacing: Spacing.small) {
            if let upgradeNotice = viewModel.upgradeNotice {
                UpgradeNoticeBanner(notice: upgradeNotice)
            }
            Picker(
                "Що показувати",
                selection: Binding(
                    get: { viewModel.scope },
                    set: { viewModel.didSelectScope($0) }
                )
            ) {
                ForEach(FeedScope.allCases, id: \.self) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            kindChips
            if let status = viewModel.homeStatus {
                FeedHomeCard(status: status)
            }
            ForEach(viewModel.pinnedRows) { row in
                pinnedRow(row)
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .background(.bar)
    }

    var kindChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(FeedKindFilter.allCases, id: \.self) { filter in
                    chip(filter)
                }
            }
        }
    }

    func chip(_ filter: FeedKindFilter) -> some View {
        let isSelected = viewModel.kindFilter == filter
        let isLocked = filter != .all && !viewModel.isPlusActive
        return Button {
            viewModel.didSelectKindFilter(filter)
        } label: {
            HStack(spacing: Spacing.xSmall) {
                Text(filter.title)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .imageScale(.small)
                }
            }
            .font(.app(.footnote, weight: .semibold))
            .foregroundStyle(isSelected ? Color.onAccent : Color.ink)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.xSmall)
            .background(isSelected ? Color.accentColor : Color.surface, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isLocked ? "Доступно в AirRaid Плюс" : "")
    }

    func pinnedRow(_ row: FeedRow) -> some View {
        Button {
            viewModel.didTapRow(id: row.id)
        } label: {
            HStack(spacing: Spacing.small) {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.alertRedInk)
                Text(row.title)
                    .font(.app(.subheadline, weight: .bold))
                    .foregroundStyle(.ink)
                if let subtitle = row.proximityText ?? row.subtitle {
                    Text(subtitle)
                        .font(.app(.footnote))
                        .foregroundStyle(.inkMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.small)
            .background(Color.alertRedSoft, in: .rect(cornerRadius: Radius.medium))
        }
        .buttonStyle(.plain)
    }

    var voiceButton: some View {
        Button(action: viewModel.didToggleVoice) {
            Label(
                viewModel.isVoiceLive ? "Вимкнути голосовий ефір" : "Увімкнути голосовий ефір",
                systemImage: viewModel.isVoiceLive ? "speaker.wave.2.fill" : "speaker.slash"
            )
            .symbolEffect(.variableColor.iterative, isActive: viewModel.isSpeaking)
        }
        .tint(viewModel.isVoiceLive ? .accentColor : .inkMuted)
    }

    var historyUpsell: some View {
        Button(action: viewModel.didTapHistoryUpsell) {
            Label(
                "Ще \(viewModel.hiddenHistoryCount) старіших — історія за 90 днів у AirRaid Плюс",
                systemImage: "clock.arrow.circlepath"
            )
            .font(.app(.footnote, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(Spacing.medium)
            .background(Color.accentSoft, in: .rect(cornerRadius: Radius.medium))
            .foregroundStyle(.accentInk)
        }
        .buttonStyle(.plain)
    }

    var unreadDivider: some View {
        HStack(spacing: Spacing.small) {
            Rectangle().fill(Color.accentColor).frame(height: 1)
            Text("Непрочитані")
                .font(.app(.caption, weight: .semibold))
                .foregroundStyle(.accentInk)
                .fixedSize()
            Rectangle().fill(Color.accentColor).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    var emptyState: some View {
        VStack(spacing: Spacing.small) {
            InlineNote(
                viewModel.scope == .myPlaces ? "Біля ваших місць поки тихо" : "Поки тихо",
                systemImage: "checkmark.shield",
                tone: .allClear
            )
            if viewModel.scope == .myPlaces, viewModel.hasNoPlaces {
                Text("Позначте дім на мапі або дозвольте геолокацію, щоб бачити своє.")
                    .font(.app(.footnote))
                    .foregroundStyle(.inkMuted)
                    .multilineTextAlignment(.center)
            }
            Text("Ефір збирається, поки AirRaid відкритий.")
                .font(.app(.footnote))
                .foregroundStyle(.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xxLarge)
    }
}

#Preview {
    let container = DIAppContainer()
    container.setup()

    return FeedCoordinatorView(
        appContainer: container,
        factory: FeedFactory(appContainer: container)
    )
}
