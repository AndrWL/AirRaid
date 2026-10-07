//
//  BundledResourceError.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

/// Why a repository could not read a data file shipped with the app.
enum BundledResourceError: Error {

    /// The file is missing from the bundle.
    case fileNotFound(name: String)
}
