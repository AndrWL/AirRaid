//
//  DemoAirSituationRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import Foundation

/// Cycles through hard-coded air situations — for previews and for working on the map without a server.
///
/// - Warning: Demo data only. The app uses ``RealtimeAirSituationRepository``.
final class DemoAirSituationRepository {

    // MARK: - Variables

    private let situationSubject: CurrentValueSubject<AirSituation, Never>
    private let eventsSubject = PassthroughSubject<[AirSituationEvent], Never>()
    private let scenarios: [AirSituation]
    private var scenarioIndex = 0
    private var cancellables: Set<AnyCancellable> = []

    /// - Parameter interval: How long each scenario stays on screen.
    init(
        interval: TimeInterval = Constants.defaultInterval
    ) {
        let scenarios = Self.makeScenarios(now: .now)
        self.scenarios = scenarios
        self.situationSubject = CurrentValueSubject(scenarios[0])
        startCycling(interval: interval)
    }
}

// MARK: - AirSituationRepositoryProtocol

extension DemoAirSituationRepository: AirSituationRepositoryProtocol {

    var situationPublisher: AnyPublisher<AirSituation, Never> {
        situationSubject.eraseToAnyPublisher()
    }

    var eventsPublisher: AnyPublisher<[AirSituationEvent], Never> {
        eventsSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private methods

private extension DemoAirSituationRepository {

    func startCycling(interval: TimeInterval) {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.showNextScenario()
            }
            .store(in: &cancellables)
    }

    func showNextScenario() {
        let previous = scenarios[scenarioIndex]
        scenarioIndex = (scenarioIndex + 1) % scenarios.count
        situationSubject.send(scenarios[scenarioIndex])
        eventsSubject.send(scenarios[scenarioIndex].events(since: previous, at: .now))
    }

    /// Three scenarios that together show every ``ThreatType`` plus a target with no type.
    static func makeScenarios(now: Date) -> [AirSituation] {
        func threat(
            _ id: String,
            _ kind: ThreatKind,
            _ type: ThreatType?,
            at position: (latitude: Double, longitude: Double),
            heading: Double?,
            speedKmh: Double?
        ) -> Threat {
            makeThreat(
                id: id,
                kind: kind,
                type: type,
                coordinate: GeoCoordinate(latitude: position.latitude, longitude: position.longitude),
                heading: heading,
                speedKmh: speedKmh ?? 0,
                now: now
            )
        }

        return [
            AirSituation(
                alerts: ["UA-30", "UA-32", "UA-74", "UA-59"].map { demoAlert(regionID: $0, now: now) },
                threats: [
                    threat("shahed-1", .drone, .shahed, at: (51.49, 31.29), heading: 200, speedKmh: 180),
                    threat("shahed-2", .drone, .shahed, at: (50.91, 34.80), heading: 235, speedKmh: 180),
                    threat("jet-1", .drone, .jetDrone, at: (50.60, 32.90), heading: 250, speedKmh: 450),
                    threat("cruise-1", .missile, .cruiseMissile, at: (50.35, 29.95), heading: 60, speedKmh: 750)
                ]
            ),
            AirSituation(
                alerts: ["UA-30", "UA-63", "UA-12", "UA-23"].map { demoAlert(regionID: $0, now: now) },
                threats: [
                    threat("ballistic-1", .ballisticMissile, .ballisticMissile, at: (49.99, 36.23), heading: 230, speedKmh: nil),
                    threat("recon-1", .drone, .reconDrone, at: (48.46, 35.04), heading: 300, speedKmh: 120),
                    threat("molniya-1", .drone, .molniya, at: (48.25, 36.40), heading: 280, speedKmh: 150),
                    threat("kab-1", .guidedAerialBomb, .guidedAerialBomb, at: (47.84, 35.14), heading: 250, speedKmh: nil),
                    threat("fpv-1", .fpv, .fpv, at: (47.60, 37.30), heading: nil, speedKmh: nil),
                    threat("fast-1", .missile, .highSpeedTarget, at: (48.90, 33.00), heading: 280, speedKmh: 1200)
                ]
            ),
            AirSituation(
                alerts: ["UA-63", "UA-14"].map { demoAlert(regionID: $0, now: now) },
                threats: [
                    threat("uav-1", .drone, .drone, at: (49.70, 37.10), heading: 260, speedKmh: 160),
                    threat("missile-1", .missile, .missile, at: (49.20, 38.20), heading: 240, speedKmh: 750),
                    threat("target-1", .unknown, nil, at: (50.10, 35.50), heading: nil, speedKmh: nil),
                    threat("aviation-1", .aviation, .aviation, at: (49.00, 39.60), heading: 270, speedKmh: nil)
                ]
            )
        ]
    }

    static func demoAlert(
        regionID: String,
        now: Date
    ) -> RegionAlert {
        RegionAlert(
            id: regionID,
            kind: .airRaid,
            level: .red,
            scope: .oblast,
            name: regionID,
            regionID: regionID,
            district: nil,
            startedAt: now
        )
    }

    // swiftlint:disable:next function_parameter_count
    static func makeThreat(
        id: String,
        kind: ThreatKind,
        type: ThreatType?,
        coordinate: GeoCoordinate,
        heading: Double?,
        speedKmh: Double,
        now: Date
    ) -> Threat {
        Threat(
            id: id,
            kind: kind,
            type: type,
            count: nil,
            level: .high,
            confidence: Constants.confidence,
            sourceCount: Constants.sourceCount,
            position: ThreatPlace(name: id, coordinate: coordinate),
            target: nil,
            trail: [],
            area: ThreatArea(name: Constants.areaName, regionID: Constants.areaID, center: coordinate),
            positionQuality: .confirmed,
            accuracyKm: Constants.accuracyKm,
            heading: heading,
            approachBearing: nil,
            speedKmh: speedKmh,
            speedSource: .typical,
            movedAt: now,
            firstSeenAt: now,
            updatedAt: now,
            expiresAt: now.addingTimeInterval(Constants.lifetime),
            summary: nil
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let defaultInterval: TimeInterval = 5
    static let confidence = 0.95
    static let sourceCount = 3
    static let accuracyKm: Double = 5
    static let lifetime: TimeInterval = 15 * 60
    static let areaName = "Демо"
    static let areaID = "UA-DEMO"
}
