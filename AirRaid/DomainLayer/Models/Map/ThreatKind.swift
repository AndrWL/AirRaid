//
//  ThreatKind.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// The broad category of a threat, always known.
///
/// Mirrors the backend's `kind`. ``ThreatType`` refines it when the source says more.
nonisolated enum ThreatKind: CaseIterable, Sendable {

    /// Drones of any kind except FPV: Shahed, jet, reconnaissance, or unspecified.
    case drone

    /// FPV drones and loitering munitions such as Lancet.
    case fpv

    /// Guided aerial bombs.
    case guidedAerialBomb

    /// Cruise missiles, high-speed targets, and missiles without further detail.
    case missile

    /// Ballistic missiles: Iskander, KN-23, Kinzhal, Zircon.
    case ballisticMissile

    /// Military aircraft: MiG-31, Tu-95/160/22, Su-30–35.
    case aviation

    /// A target with no type yet; refined to ``drone`` or ``missile`` once known.
    case unknown
}
