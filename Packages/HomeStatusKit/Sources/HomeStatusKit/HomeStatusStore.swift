//
//  HomeStatusStore.swift
//  HomeStatusKit
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation

/// Reads and writes the ``HomeStatusSnapshot`` as a JSON file in the App Group container.
///
/// A file rather than shared `UserDefaults`: the snapshot carries a mini-map of a few thousand points, and the
/// extension reads it whole on every timeline reload anyway.
public struct HomeStatusStore: Sendable {

    /// `nil` when the app is signed without the App Group (a free Personal Team): there is nowhere to share through.
    public let fileURL: URL?

    /// - Parameter containerURL: The shared container; `nil` when the group is not in the entitlements.
    public init(containerURL: URL?) {
        fileURL = containerURL?.appending(path: Constants.fileName, directoryHint: .notDirectory)
    }

    /// The store in the running app's (or extension's) App Group container.
    public init() {
        self.init(containerURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier))
    }

    /// Whether there is a shared container to write to.
    public var isAvailable: Bool {
        fileURL != nil
    }

    /// The last snapshot the app wrote, or `nil` before the first one or without a shared container.
    ///
    /// - Throws: An error if the file exists but cannot be read or decoded.
    public func load() throws -> HomeStatusSnapshot? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try Self.makeDecoder().decode(HomeStatusSnapshot.self, from: data)
    }

    /// Replaces the snapshot atomically, so the extension never reads half a file.
    ///
    /// - Throws: ``HomeStatusStoreError/containerUnavailable`` without a shared container, or a write error.
    public func save(_ snapshot: HomeStatusSnapshot) throws {
        guard let fileURL else { throw HomeStatusStoreError.containerUnavailable }
        let data = try Self.makeEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - HomeStatusStoreError

public enum HomeStatusStoreError: Error, Equatable {

    /// The App Group is missing from the entitlements, so the app and the extension share no container.
    case containerUnavailable
}

// MARK: - Private methods

private extension HomeStatusStore {

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}

// MARK: - Constants

private enum Constants {
    static let fileName = "home-status.json"
}
