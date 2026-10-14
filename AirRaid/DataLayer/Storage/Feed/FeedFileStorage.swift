//
//  FeedFileStorage.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Foundation

/// Keeps the feed in one JSON file in Application Support, out of iCloud backups: it is a cache of public data.
///
/// A few thousand small bubbles at most, written at most every few seconds, so a whole-file write is simpler than a
/// database and fast enough.
nonisolated struct FeedFileStorage: Sendable {

    // MARK: - Variables

    private let fileURL: URL?

    init(fileURL: URL? = Self.defaultFileURL) {
        self.fileURL = fileURL
    }

    // MARK: - Methods

    /// An empty list when there is no file yet.
    ///
    /// - Throws: When the file exists but cannot be read or decoded.
    func load() throws -> [FeedItem] {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let file = try JSONDecoder().decode(FeedFileEntity.self, from: data)
        guard file.version == Constants.version else { return [] }
        return file.items.compactMap(FeedItemEntityMapper.map)
    }

    /// - Throws: When the file cannot be written.
    func save(_ items: [FeedItem]) throws {
        guard var fileURL else { return }
        let file = FeedFileEntity(version: Constants.version, items: items.map(FeedItemEntityMapper.map))
        let data = try JSONEncoder().encode(file)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try fileURL.setResourceValues(values)
    }

    static var defaultFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Constants.fileName)
    }
}

/// The file's top level: a format version, so a future change can start over instead of failing.
nonisolated private struct FeedFileEntity: Codable {
    let version: Int
    let items: [FeedItemEntity]
}

// MARK: - Constants

nonisolated private enum Constants {
    static let fileName = "feed.json"
    static let version = 1
}
