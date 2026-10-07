//
//  ThreatIcon.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import UIKit

/// The pin image for a threat: a white top-down silhouette pointing north, rotated on the map by the heading
/// (except the side-on UFO for targets of unknown type).
///
/// Chosen by ``ThreatType`` when known, otherwise by ``ThreatKind``. The silhouettes are vector assets in
/// `Assets.xcassets/Threats`, named `threat-<case>`.
/// - Note: ``shahed`` is traced from a Wikimedia Commons drawing (CC BY 4.0, see the SVG); it must be
///   credited on the licenses screen.
enum ThreatIcon: String, CaseIterable {

    case shahed
    case jetDrone
    case reconDrone
    case drone
    case fpv
    case guidedAerialBomb
    case cruiseMissile
    case highSpeedTarget
    case missile
    case ballisticMissile
    case aviation
    case unknown

    // MARK: - Variables

    /// The name the image is registered under in the map style; also the asset name.
    var name: String {
        Constants.namePrefix + rawValue
    }

    /// Whether the icon turns with the heading. The UFO is drawn side-on and must stay upright.
    var rotatesWithHeading: Bool {
        self != .unknown
    }

    /// The asset with a soft dark glow, so it reads on both the dark map and the red alert fill.
    ///
    /// The glow is drawn here because asset-catalog SVGs do not support blur.
    var image: UIImage {
        guard let silhouette = UIImage(named: name) else {
            assertionFailure("[ThreatIcon] Missing asset: \(name)")
            return UIImage()
        }
        let padding = Constants.glowBlur
        let size = CGSize(
            width: silhouette.size.width + padding * 2,
            height: silhouette.size.height + padding * 2
        )
        return UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.setShadow(offset: .zero, blur: Constants.glowBlur, color: UIColor.black.cgColor)
            silhouette.draw(at: CGPoint(x: padding, y: padding))
        }
    }

    init(_ threat: Threat) {
        if let type = threat.type {
            self.init(type)
        } else {
            self.init(threat.kind)
        }
    }
}

// MARK: - Private methods

private extension ThreatIcon {

    // One case per type: an exhaustive switch keeps a new backend type from silently getting no icon.
    // swiftlint:disable:next cyclomatic_complexity
    init(_ type: ThreatType) {
        switch type {
        case .shahed: self = .shahed
        case .jetDrone: self = .jetDrone
        case .reconDrone: self = .reconDrone
        case .drone: self = .drone
        case .fpv: self = .fpv
        case .guidedAerialBomb: self = .guidedAerialBomb
        case .cruiseMissile: self = .cruiseMissile
        case .highSpeedTarget: self = .highSpeedTarget
        case .missile: self = .missile
        case .ballisticMissile: self = .ballisticMissile
        case .aviation: self = .aviation
        }
    }

    /// The generic icon of each category, for threats whose type is not named.
    init(_ kind: ThreatKind) {
        switch kind {
        case .drone: self = .drone
        case .fpv: self = .fpv
        case .guidedAerialBomb: self = .guidedAerialBomb
        case .missile: self = .missile
        case .ballisticMissile: self = .ballisticMissile
        case .aviation: self = .aviation
        case .unknown: self = .unknown
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let namePrefix = "threat-"
    static let glowBlur: CGFloat = 3
}
