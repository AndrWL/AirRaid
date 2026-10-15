//
//  PlusFeatureList.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// What AirRaid Плюс adds, and what stays free — said first, so nobody thinks safety is for sale.
struct PlusFeatureList: View {

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("AirRaid Плюс")
                    .font(.app(.largeTitle, weight: .bold))
                    .foregroundStyle(.ink)
                Text(
                    "Тривоги, загрози на мапі, ефір і попередження біля дому — завжди безкоштовні. "
                        + "Плюс додає зручності й підтримує проєкт."
                )
                    .font(.app(.subheadline))
                    .foregroundStyle(.inkMuted)
            }
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text(feature.title)
                            .font(.app(.body, weight: .semibold))
                            .foregroundStyle(.ink)
                        Text(feature.details)
                            .font(.app(.footnote))
                            .foregroundStyle(.inkMuted)
                    }
                } icon: {
                    Image(systemName: feature.systemImage)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - PremiumFeature

extension PremiumFeature {

    var title: String {
        switch self {
        case .extraPlaces: "Більше місць"
        case .extendedHistory: "Історія за 90 днів"
        case .feedFilters: "Фільтри ефіру"
        case .nightReport: "Нічний звіт"
        case .voiceRules: "Правила голосу"
        }
    }

    var details: String {
        switch self {
        case .extraPlaces: "До \(PremiumLimits.plusPlaces) місць зі своїми назвами й радіусами: батьки, робота, школа."
        case .extendedHistory: "Безкоштовно ефір пам'ятає добу."
        case .feedFilters: "Лише ракети, лише КАБи, лише тривоги — без шуму."
        case .nightReport: "Зранку: скільки тривало і що летіло біля ваших місць."
        case .voiceRules: "Що читати вголос, для яких місць і як швидко."
        }
    }

    var systemImage: String {
        switch self {
        case .extraPlaces: "mappin.and.ellipse"
        case .extendedHistory: "clock.arrow.circlepath"
        case .feedFilters: "line.3.horizontal.decrease.circle"
        case .nightReport: "moon.stars"
        case .voiceRules: "waveform"
        }
    }
}

#Preview {
    PlusFeatureList()
        .padding()
}
