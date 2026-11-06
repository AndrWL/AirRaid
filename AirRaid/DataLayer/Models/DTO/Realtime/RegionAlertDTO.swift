//
//  RegionAlertDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// An official alert (alerts.in.ua) as the Nebo API relays it.
///
/// `threats` and `oblast_uid` are not decoded yet: the map only needs where and since when.
nonisolated struct RegionAlertDTO: Decodable, Sendable {

    let uid: String
    /// `air_raid`, `artillery_shelling`, `urban_fights`, `chemical`, `nuclear`.
    let kind: String
    /// `red`, `yellow`, or `null`.
    let level: String?
    /// `oblast`, `raion`, `hromada`, `city`, `unknown`.
    let locationType: String
    let name: String
    let oblast: String?
    /// The raion a hromada lies in, e.g. Nikopol Raion; `null` for oblasts, raions, and cities.
    let raion: String?
    /// The oblast's ISO 3166-2:UA code, as for events.
    let code: String
    let since: Int

    enum CodingKeys: String, CodingKey {
        case uid, kind, level, name, oblast, raion, code, since
        case locationType = "location_type"
    }
}
