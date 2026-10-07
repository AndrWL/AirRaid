//
//  DemoAirSituationRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import Foundation

/// Cycles through hard-coded air situations so the map can be built before the backend exists.
///
/// - Warning: Demo data only. Replace with a repository that decodes ``RealtimeServiceProtocol`` messages
///   once the backend message format is agreed.
final class DemoAirSituationRepository {

    // MARK: - Variables

    private let situationSubject: CurrentValueSubject<AirSituation, Never>
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
        scenarioIndex = (scenarioIndex + 1) % scenarios.count
        situationSubject.send(scenarios[scenarioIndex])
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
            Threat(
                id: id,
                kind: kind,
                type: type,
                coordinate: GeoCoordinate(latitude: position.latitude, longitude: position.longitude),
                heading: heading,
                speedKmh: speedKmh,
                detectedAt: now
            )
        }

        return [
            AirSituation(
                alerts: ["UA-30", "UA-32", "UA-74", "UA-59"].map { RegionAlert(regionID: $0, startedAt: now) },
                threats: [
                    threat("shahed-1", .drone, .shahed, at: (51.49, 31.29), heading: 200, speedKmh: 180),
                    threat("shahed-2", .drone, .shahed, at: (50.91, 34.80), heading: 235, speedKmh: 180),
                    threat("jet-1", .drone, .jetDrone, at: (50.60, 32.90), heading: 250, speedKmh: 450),
                    threat("cruise-1", .missile, .cruiseMissile, at: (50.35, 29.95), heading: 60, speedKmh: 750)
                ]
            ),
            AirSituation(
                alerts: ["UA-30", "UA-63", "UA-12", "UA-23"].map { RegionAlert(regionID: $0, startedAt: now) },
                threats: [
                    threat("ballistic-1", .ballisticMissile, .ballisticMissile, at: (49.99, 36.23), heading: 230, speedKmh: nil),
                    threat("recon-1", .drone, .reconDrone, at: (48.46, 35.04), heading: 300, speedKmh: 120),
                    threat("kab-1", .guidedAerialBomb, .guidedAerialBomb, at: (47.84, 35.14), heading: 250, speedKmh: nil),
                    threat("fpv-1", .fpv, .fpv, at: (47.60, 37.30), heading: nil, speedKmh: nil),
                    threat("fast-1", .missile, .highSpeedTarget, at: (48.90, 33.00), heading: 280, speedKmh: 1200)
                ]
            ),
            AirSituation(
                alerts: ["UA-63", "UA-14"].map { RegionAlert(regionID: $0, startedAt: now) },
                threats: [
                    threat("uav-1", .drone, .drone, at: (49.70, 37.10), heading: 260, speedKmh: 160),
                    threat("missile-1", .missile, .missile, at: (49.20, 38.20), heading: 240, speedKmh: 750),
                    threat("target-1", .unknown, nil, at: (50.10, 35.50), heading: nil, speedKmh: nil),
                    threat("aviation-1", .aviation, .aviation, at: (49.00, 39.60), heading: 270, speedKmh: nil)
                ]
            )
        ]
    }
}

// MARK: - Constants

private enum Constants {
    static let defaultInterval: TimeInterval = 5
}
