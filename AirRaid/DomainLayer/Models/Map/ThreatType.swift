//
//  ThreatType.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// The specific type of a threat, when the source names it.
///
/// Mirrors the backend's `type`. It can be refined during a threat's life — a Shahed reported as "jet"
/// becomes ``jetDrone`` — so never cache anything by it.
nonisolated enum ThreatType: CaseIterable, Sendable {

    // MARK: - Drones

    /// Shahed / Geran attack drone.
    case shahed

    /// Jet-powered attack drone (Geran-3 and similar).
    case jetDrone

    /// Reconnaissance drone: Orlan, Zala, Supercam.
    case reconDrone

    /// Molniya-2: a slow (about 150 km/h) plywood fixed-wing FPV drone, not a jet.
    case molniya

    /// A drone without further detail.
    case drone

    // MARK: - Other

    /// FPV drone or Lancet.
    case fpv

    /// Guided aerial bomb.
    case guidedAerialBomb

    // MARK: - Missiles

    /// Cruise missile: Kalibr, Kh-101/555/59/69/22, Onyx.
    case cruiseMissile

    /// A target reported only as "high-speed".
    case highSpeedTarget

    /// A missile without further detail.
    case missile

    /// Ballistic missile.
    case ballisticMissile

    // MARK: - Aircraft

    /// Military aircraft.
    case aviation
}
