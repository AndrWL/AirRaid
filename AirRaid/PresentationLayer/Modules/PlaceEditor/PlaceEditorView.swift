//
//  PlaceEditorView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// A saved place in the settings: its name (a custom place only), where it is, the radius, and moving or removing it.
struct PlaceEditorView<ViewModel: PlaceEditorViewModelProtocol>: View {

    // MARK: - Variables

    @Bindable private var viewModel: ViewModel
    @State private var isRemoveConfirmationPresented = false
    @FocusState private var isNameFocused: Bool

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if let place = viewModel.place {
                details(place)
            } else {
                ContentUnavailableView("Місце прибрано", systemImage: "mappin.slash")
            }
        }
        .background(Color.appBackground)
        .navigationTitle(viewModel.place?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
        // A name typed and left without "Done" is still kept.
        .onDisappear(perform: viewModel.didCommitName)
    }
}

// MARK: - Sections

private extension PlaceEditorView {

    func details(_ place: SettingsPlaceContent) -> some View {
        List {
            if place.kind == .custom {
                nameSection
            }
            addressSection(place)
            radiusSection(place)
            actionsSection(place)
        }
        .font(.app(.body))
        .scrollContentBackground(.hidden)
    }

    var nameSection: some View {
        Section {
            TextField(viewModel.namePlaceholder, text: $viewModel.name)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit(viewModel.didCommitName)
                .foregroundStyle(.ink)
        } header: {
            Text("Назва")
        } footer: {
            footerText("Так місце підписано на мапі та в ефірі: «12 км від „Робота“». Без назви — назвою населеного пункту.")
        }
        .listRowBackground(Color.surface)
    }

    func addressSection(_ place: SettingsPlaceContent) -> some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(place.street ?? place.placeLine ?? "Адресу визначаємо…")
                        .foregroundStyle(.ink)
                    if place.street != nil, let placeLine = place.placeLine {
                        Text(placeLine)
                            .font(.app(.footnote))
                            .foregroundStyle(.inkMuted)
                    }
                }
            } icon: {
                Image(systemName: place.kind.systemImage)
                    .foregroundStyle(place.kind.tint)
            }
            .accessibilityElement(children: .combine)
            if place.isPaused {
                InlineNote(
                    "Призупинено: без AirRaid Плюс стежимо лише за домом і вашою геолокацією",
                    systemImage: "pause.circle",
                    tone: .warning
                )
            }
            Button(action: viewModel.didTapMoveOnMap) {
                Label("Перемістити на мапі", systemImage: "mappin.and.ellipse")
            }
            .font(.app(.body, weight: .semibold))
        } header: {
            Text("Де")
        }
        .listRowBackground(Color.surface)
    }

    func radiusSection(_ place: SettingsPlaceContent) -> some View {
        Section {
            Picker(
                "Радіус",
                selection: Binding(
                    get: { place.radiusKm },
                    set: { viewModel.didSelectRadius($0) }
                )
            ) {
                ForEach(viewModel.radiusOptions, id: \.self) { radius in
                    Text(DisplayTime.distance(radius)).tag(radius)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Радіус навколо місця")
        } header: {
            Text("Радіус")
        } footer: {
            footerText("Загрози в цьому радіусі з'являються в картці на мапі, а в ефірі — з відстанню до місця.")
        }
        .listRowBackground(Color.surface)
    }

    func actionsSection(_ place: SettingsPlaceContent) -> some View {
        Section {
            Button(place.kind == .home ? "Видалити дім" : "Видалити місце", role: .destructive) {
                isRemoveConfirmationPresented = true
            }
            .font(.app(.body, weight: .semibold))
            // On the button, so the popover points at it.
            .confirmationDialog(
                removeTitle(place),
                isPresented: $isRemoveConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Видалити", role: .destructive, action: viewModel.didConfirmRemove)
            } message: {
                Text("AirRaid перестане стежити за загрозами в радіусі цього місця.")
            }
        } footer: {
            footerText("Місця зберігаються лише на цьому пристрої.")
        }
        .listRowBackground(Color.surface)
    }
}

// MARK: - Components

private extension PlaceEditorView {

    func removeTitle(_ place: SettingsPlaceContent) -> String {
        place.kind == .home ? "Видалити дім?" : "Видалити «\(place.title)»?"
    }

    func footerText(_ text: String) -> some View {
        Text(text)
            .font(.app(.footnote))
            .foregroundStyle(.inkMuted)
    }
}
