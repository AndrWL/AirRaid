//
//  FeedRepository.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation
import OSLog

/// The feed, built on the device from the air situation's changes and kept in a file.
///
/// Strategy: the «Небо» API has no feed history yet, so the feed is what this device saw. Each batch of
/// ``AirSituationEvent``s goes through ``FeedBuilder``; then bubbles whose threat or alert is gone from the situation
/// are closed (they ended while the app was closed), and bubbles that ended more than ``PremiumLimits/plusHistory``
/// ago are dropped. The file is written a few seconds after the last change.
///
/// - Note: Whatever happened while the app was closed is missing. A server-side feed (`GET /v1/feed`) is the fix.
final class FeedRepository {

    // MARK: - Variables

    private let airSituationRepository: AirSituationRepositoryProtocol
    private let storage: FeedFileStorage
    private let defaults: UserDefaults
    private let itemsSubject: CurrentValueSubject<[FeedItem], Never>
    private let entriesSubject = PassthroughSubject<[FeedEntry], Never>()
    private let lastReadAtSubject: CurrentValueSubject<Date?, Never>
    private let saveRequests = PassthroughSubject<Void, Never>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var builder: FeedBuilder
    private var situation: AirSituation = .empty
    private var isStarted = false
    private var cancellables: Set<AnyCancellable> = []

    init(
        airSituationRepository: AirSituationRepositoryProtocol,
        storage: FeedFileStorage = FeedFileStorage(),
        defaults: UserDefaults = .standard
    ) {
        self.airSituationRepository = airSituationRepository
        self.storage = storage
        self.defaults = defaults
        let items: [FeedItem]
        do {
            items = try storage.load()
        } catch {
            items = []
            Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)
                .error("Failed to load the feed, starting empty: \(String(describing: error), privacy: .public)")
        }
        self.builder = FeedBuilder(items: items)
        self.itemsSubject = CurrentValueSubject(Self.sorted(items))
        self.lastReadAtSubject = CurrentValueSubject(defaults.object(forKey: Constants.lastReadAtKey) as? Date)
    }
}

// MARK: - FeedRepositoryProtocol

extension FeedRepository: FeedRepositoryProtocol {

    var itemsPublisher: AnyPublisher<[FeedItem], Never> {
        itemsSubject.eraseToAnyPublisher()
    }

    var entriesPublisher: AnyPublisher<[FeedEntry], Never> {
        entriesSubject.eraseToAnyPublisher()
    }

    var lastReadAtPublisher: AnyPublisher<Date?, Never> {
        lastReadAtSubject.eraseToAnyPublisher()
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        // The repository publishes the situation before the events behind it, so the latest one is current when a
        // batch arrives.
        airSituationRepository.situationPublisher
            .sink { [weak self] situation in
                self?.situation = situation
            }
            .store(in: &cancellables)

        airSituationRepository.eventsPublisher
            .sink { [weak self] events in
                self?.handle(events)
            }
            .store(in: &cancellables)

        saveRequests
            .debounce(for: Constants.saveDelay, scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.save()
            }
            .store(in: &cancellables)
    }

    func markRead(upTo date: Date) {
        guard date > (lastReadAtSubject.value ?? .distantPast) else { return }
        defaults.set(date, forKey: Constants.lastReadAtKey)
        lastReadAtSubject.send(date)
    }
}

// MARK: - Private methods

private extension FeedRepository {

    func handle(_ events: [AirSituationEvent]) {
        let now = Date()
        let entries = builder.apply(events, now: now)
        builder.reconcile(with: situation, now: now)
        builder.prune(endedBefore: now.addingTimeInterval(-PremiumLimits.plusHistory))
        itemsSubject.send(Self.sorted(Array(builder.items.values)))
        saveRequests.send()
        if !entries.isEmpty {
            entriesSubject.send(entries)
        }
    }

    func save() {
        do {
            try storage.save(itemsSubject.value)
        } catch {
            logger.error("Failed to save the feed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Oldest first, like a chat; ties by id so the order never jumps.
    static func sorted(_ items: [FeedItem]) -> [FeedItem] {
        items.sorted { ($0.createdAt, $0.id) < ($1.createdAt, $1.id) }
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Feed"
    static let lastReadAtKey = "feedLastReadAt"
    static let saveDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(3)
}
