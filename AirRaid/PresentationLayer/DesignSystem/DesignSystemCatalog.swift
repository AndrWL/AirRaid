//
//  DesignSystemCatalog.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

#if DEBUG
import SwiftUI

/// Every token and component on one screen, for checking both themes and Dynamic Type in previews.
///
/// Debug only: the reference lives in the design-system artifact; this is its mirror in code.
struct DesignSystemCatalog: View {

    var body: some View {
        List {
            typography
            colors
            components
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - Sections

private extension DesignSystemCatalog {

    var typography: some View {
        Section("Типографіка · Manrope") {
            Text("Мапа").font(.app(.largeTitle, weight: .heavy))
            Text("Шахед").font(.app(.title2, weight: .bold))
            Text("Немає з'єднання").font(.app(.headline, weight: .semibold))
            Text("Курсом на Київ").font(.app(.body))
            Text("Група рухається з півдня.").font(.app(.callout)).foregroundStyle(.inkMuted)
            Text("Повітряна тривога · 1 год 4 хв").font(.app(.footnote)).foregroundStyle(.inkMuted)
            Text("1:04:17").font(.app(.largeTitle, weight: .semibold)).monospacedDigit()
        }
        .listRowBackground(Color.surface)
    }

    var colors: some View {
        Section("Кольори") {
            swatches([.appBackground, .surface, .surfaceSunken, .hairline, .ink, .inkMuted])
            swatches([.accentColor, .accentSoft, .accentInk, .onAccent, .focusRing])
            swatches([.alertRed, .alertRedSoft, .alertRedInk, .alertYellow, .alertYellowSoft, .alertYellowInk])
            swatches([.warning, .warningSoft, .warningInk, .allClear, .allClearSoft, .allClearInk])
            swatches([.mapTerritory, .mapAlertRed, .mapAlertYellow, .mapCaption])
        }
        .listRowBackground(Color.surface)
    }

    var components: some View {
        Section("Компоненти") {
            HStack {
                Badge("Достовірність: низька", tone: .neutral)
                Badge("середня", tone: .accentSoft)
                Badge("висока", tone: .accent)
            }
            HStack {
                Badge("Тривога", tone: .alertRed)
                Badge("Загроза", tone: .alertYellow)
                Badge("Застаріло", tone: .warning)
                Badge("Відбій", tone: .allClear)
                Badge.estimated
            }
            HStack(spacing: Spacing.large) {
                StatusDot(.alertRed)
                StatusDot(.alertYellow)
                StatusDot(.allClear)
                StatusDot(.unknown)
            }
            InlineNote("Даних не було 12 хв", systemImage: "clock.badge.exclamationmark", tone: .warning)
            InlineNote("Тривоги немає", systemImage: "checkmark.shield", tone: .allClear)
            HStack {
                NoticeBanner(systemImage: "wifi.slash", title: "Немає з'єднання", subtitle: "Дані станом на 21:40")
                Spacer()
                CloseButton {}
            }
            .padding(Spacing.small)
            .background(Color.mapTerritory, in: .rect(cornerRadius: Radius.medium))
        }
        .listRowBackground(Color.surface)
    }

    func swatches(_ colors: [Color]) -> some View {
        HStack(spacing: Spacing.small) {
            ForEach(colors.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: Radius.small)
                    .fill(colors[index])
                    .overlay(RoundedRectangle(cornerRadius: Radius.small).strokeBorder(.hairline))
                    .frame(height: Constants.swatchHeight)
            }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let swatchHeight: CGFloat = 28
}

#Preview("Світла") {
    DesignSystemCatalog()
        .preferredColorScheme(.light)
}

#Preview("Темна") {
    DesignSystemCatalog()
        .preferredColorScheme(.dark)
}
#endif
