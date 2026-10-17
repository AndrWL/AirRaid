//
//  MapLegendView.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import SwiftUI

/// How to read the map: what the fills, pins and lines mean, and that the map is for information only.
///
/// Static content, so no view model: the samples are drawn from the same assets and colours the map uses.
struct MapLegendView: View {

    // MARK: - Variables

    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    var body: some View {
        List {
            header
            disclaimerSection
            alertsSection
            threatsSection
            markersSection
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .sheetCloseBar(action: onClose)
    }
}

// MARK: - Sections

private extension MapLegendView {

    var header: some View {
        Section {
            Text("Як читати мапу")
                .font(.app(.title2, weight: .bold))
                .foregroundStyle(.ink)
        }
        .listRowBackground(Color.surface)
    }

    var disclaimerSection: some View {
        Section {
            InlineNote(
                "Мапа має лише інформаційний характер",
                systemImage: "exclamationmark.triangle",
                tone: .warning
            )
            Text(
                """
                Тривоги — з офіційних даних, а загрози — з відкритих моніторингових джерел: їхнє розташування, \
                курс і час можуть бути неточними або із запізненням. Порожня карта не означає, що небезпеки немає.
                """
            )
            .font(.app(.footnote))
            .foregroundStyle(.inkMuted)
            Text("Завжди реагуйте на сирену та офіційні повідомлення і прямуйте в укриття.")
                .font(.app(.footnote, weight: .semibold))
                .foregroundStyle(.ink)
        }
        .listRowBackground(Color.surface)
    }

    var alertsSection: some View {
        Section {
            row("Повітряна тривога", detail: "Область, район, Київ або Севастополь") {
                fillSample(.mapAlertRed, opacity: Constants.wholeAlertOpacity)
            }
            row("Тривога нижчого рівня", detail: "Наприклад, лише через БпЛА") {
                fillSample(.mapAlertYellow, opacity: Constants.wholeAlertOpacity)
            }
            row("Тривога в частині району", detail: "Оголошена для окремої громади") {
                fillSample(.mapAlertRed, opacity: Constants.partialAlertOpacity)
            }
        } header: {
            sectionTitle("Тривоги")
        }
        .listRowBackground(Color.surface)
    }

    var threatsSection: some View {
        Section {
            ForEach(ThreatIcon.allCases, id: \.self) { icon in
                row(icon.legendName) {
                    pinSample(Image(uiImage: icon.image))
                }
            }
        } header: {
            sectionTitle("Загрози")
        } footer: {
            footerText("Іконка повернута за курсом руху. Під нею — куди летить ціль або де її помітили.")
        }
        .listRowBackground(Color.surface)
    }

    var markersSection: some View {
        Section {
            row("Загроза поруч", detail: "У радіусі вашої геолокації чи дому") {
                pinSample(Image(uiImage: ThreatIcon.shahed.nearImage))
            }
            row("Блідий пін", detail: "Поза зоною тривоги — місце може бути визначене хибно") {
                pinSample(Image(uiImage: ThreatIcon.shahed.image), opacity: Constants.outsideAlertOpacity)
            }
            row("Прогноз", detail: "Де ціль імовірно зараз, якщо летить тим самим курсом") {
                forecastSample
            }
            row(WatchedPlaceKind.currentLocation.title, detail: "Синє коло — радіус, у якому стежимо за загрозами") {
                placeSample(.currentLocation)
            }
            row(WatchedPlaceKind.home.title, detail: "Помаранчеве коло — радіус навколо дому") {
                placeSample(.home)
            }
        } header: {
            sectionTitle("Позначки")
        } footer: {
            footerText("Торкніться загрози чи області, щоб побачити подробиці.")
        }
        .listRowBackground(Color.surface)
    }
}

// MARK: - Components

private extension MapLegendView {

    func row<Sample: View>(
        _ title: String,
        detail: String? = nil,
        @ViewBuilder sample: () -> Sample
    ) -> some View {
        HStack(spacing: Spacing.medium) {
            sample()
                .frame(width: Constants.sampleSize, height: Constants.sampleSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(title)
                    .font(.app(.body, weight: .semibold))
                    .foregroundStyle(.ink)
                if let detail {
                    Text(detail)
                        .font(.app(.footnote))
                        .foregroundStyle(.inkMuted)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// A patch of the map's dark land with the alert fill over it, the way an oblast looks.
    func fillSample(_ color: Color, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: Radius.small)
            .fill(Color.mapDim)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.small)
                    .fill(color.opacity(opacity))
            }
    }

    /// The map's own pin image on a dark tile: the white silhouettes would vanish on a light sheet.
    func pinSample(_ image: Image, opacity: Double = 1) -> some View {
        RoundedRectangle(cornerRadius: Radius.small)
            .fill(Color.mapDim)
            .overlay {
                image
                    .resizable()
                    .scaledToFit()
                    .padding(Spacing.xSmall)
                    .opacity(opacity)
            }
    }

    /// The faint ghost ahead of the pin, joined to it by a dotted line.
    var forecastSample: some View {
        RoundedRectangle(cornerRadius: Radius.small)
            .fill(Color.mapDim)
            .overlay {
                GeometryReader { proxy in
                    let pinCenter = CGPoint(x: proxy.size.width * 0.3, y: proxy.size.height * 0.7)
                    let ghostCenter = CGPoint(x: proxy.size.width * 0.72, y: proxy.size.height * 0.28)
                    Path { path in
                        path.move(to: pinCenter)
                        path.addLine(to: ghostCenter)
                    }
                    .stroke(Color.mapTrack.opacity(Constants.forecastLinkOpacity), style: Constants.forecastLinkStyle)
                    forecastPin(opacity: Constants.forecastGhostOpacity)
                        .position(ghostCenter)
                    forecastPin(opacity: 1)
                        .position(pinCenter)
                }
            }
    }

    func forecastPin(opacity: Double) -> some View {
        Image(uiImage: ThreatIcon.shahed.image)
            .resizable()
            .scaledToFit()
            .rotationEffect(Constants.forecastHeading)
            .frame(width: Constants.forecastPinSize, height: Constants.forecastPinSize)
            .opacity(opacity)
    }

    /// The place's dot inside its radius ring.
    func placeSample(_ kind: WatchedPlaceKind) -> some View {
        ZStack {
            Circle()
                .fill(kind.tint.opacity(Constants.placeRadiusFillOpacity))
            Circle()
                .strokeBorder(kind.tint, lineWidth: Constants.placeRadiusWidth)
            Image(systemName: kind.systemImage)
                .font(.app(.caption2, weight: .bold))
                .foregroundStyle(kind.tint)
        }
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.app(.footnote, weight: .semibold))
            .foregroundStyle(.inkMuted)
    }

    func footerText(_ text: String) -> some View {
        Text(text)
            .font(.app(.footnote))
            .foregroundStyle(.inkMuted)
    }

}

// MARK: - ThreatIcon

private extension ThreatIcon {

    /// The name of what the icon stands for, in the words the threat sheet uses.
    var legendName: String {
        switch self {
        case .shahed: ThreatType.shahed.displayName
        case .jetDrone: ThreatType.jetDrone.displayName
        case .reconDrone: ThreatType.reconDrone.displayName
        case .molniya: ThreatType.molniya.displayName
        case .drone: ThreatType.drone.displayName
        case .fpv: ThreatType.fpv.displayName
        case .guidedAerialBomb: ThreatType.guidedAerialBomb.displayName
        case .cruiseMissile: ThreatType.cruiseMissile.displayName
        case .highSpeedTarget: ThreatType.highSpeedTarget.displayName
        case .missile: ThreatType.missile.displayName
        case .ballisticMissile: ThreatType.ballisticMissile.displayName
        case .aviation: ThreatType.aviation.displayName
        case .unknown: "Ціль невідомого типу"
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let sampleSize: CGFloat = 40
    // Match `MapLayerStyle`, which lives with MapLibre and is not visible here.
    static let wholeAlertOpacity: Double = 0.7
    static let partialAlertOpacity: Double = 0.35
    static let outsideAlertOpacity: Double = 0.4
    static let forecastGhostOpacity: Double = 0.35
    static let forecastLinkOpacity: Double = 0.4
    static let forecastLinkStyle = StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [1, 3])
    static let forecastPinSize: CGFloat = 18
    static let forecastHeading = Angle.degrees(45)
    static let placeRadiusFillOpacity: Double = 0.15
    static let placeRadiusWidth: CGFloat = 1.5
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            MapLegendView {}
                .presentationDetents([.medium, .large])
        }
}
