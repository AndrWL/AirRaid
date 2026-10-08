//
//  FailableDTO.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Decodes `Wrapped`, or `nil` if that element is malformed, so one bad element does not fail a whole array.
///
/// Decode `[FailableDTO<T>]` and `compactMap(\.value)`.
nonisolated struct FailableDTO<Wrapped: Decodable & Sendable>: Decodable, Sendable {

    let value: Wrapped?

    init(from decoder: Decoder) throws {
        // Dropping the element is the point: the rest of the array is still usable.
        value = try? Wrapped(from: decoder)
    }
}
