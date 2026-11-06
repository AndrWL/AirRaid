//
//  FeedViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 14.10.2026.
//

import Combine
import Foundation
import HomeStatusKit

/// The view model of the Feed tab.
///
/// Rows are rebuilt from the kept bubbles whenever the feed, the live situation, the places, the filters or Plus
/// change, and every ``Constants/refreshInterval`` for the distances, which move with the forecast.
@Observable
final class FeedViewModel<Router: FeedRouterProtocol>: BaseViewModel {

    /// The repositories and services the feed reads, grouped to keep the initializer short.
    struct Dependencies {
        let feedRepository: FeedRepositoryProtocol
        let airSituationRepository: AirSituationRepositoryProtocol
        let watchedPlacesProvider: WatchedPlacesProviding
        let watchedRegionsProvider: WatchedRegionsProviding
        let entitlementService: EntitlementServiceProtocol
        let voiceAnnouncer: FeedVoiceAnnouncing
        let homeStatusBroadcaster: HomeStatusBroadcasting
        let realtimeService: RealtimeServiceProtocol
    }

    // MARK: - Variables

    private(set) var rows: [FeedRow] = []
    private(set) var pinnedRows: [FeedRow] = []
    private(set) var homeStatus: HomeStatus?
    private(set) var scope: FeedScope = .myPlaces
    private(set) var kindFilter: FeedKindFilter = .all
    private(set) var isPlusActive = false
    private(set) var firstUnreadID: String?
    private(set) var hiddenHistoryCount = 0
    private(set) var isVoiceLive = false
    private(set) var isSpeaking = false
    private(set) var hasNoPlaces = true
    private(set) var upgradeNotice: UpgradeNotice?

    @ObservationIgnored
    private let router: Router

    @ObservationIgnored
    private let dependencies: Dependencies

    @ObservationIgnored
    private let appStoreURL: URL?

    @ObservationIgnored
    private var items: [FeedItem] = []

    @ObservationIgnored
    private var situation: AirSituation = .empty

    @ObservationIgnored
    private var places: [WatchedPlace] = []

    @ObservationIgnored

    @ObservationIgnored
    private var regionIDs: Set<String> = []

    @ObservationIgnored
    private var lastReadAt: Date?

    /// What was read before this visit: the "Unread" divider stays put while the user scrolls.
    @ObservationIgnored
    private var readAnchor: Date?

    @ObservationIgnored
    private var isVisible = false

    init(
        router: Router,
        dependencies: Dependencies,
        appStoreURL: URL?
    ) {
        self.router = router
        self.dependencies = dependencies
        self.appStoreURL = appStoreURL
        super.init()
    }
}

// MARK: - FeedViewModelProtocol

extension FeedViewModel: FeedViewModelProtocol {

    func onAppear() {
        if cancellables.isEmpty {
            bind()
        }
        isVisible = true
        readAnchor = lastReadAt
        dependencies.feedRepository.markRead(upTo: .now)
        rebuild()
    }

    func onDisappear() {
        isVisible = false
        dependencies.feedRepository.markRead(upTo: .now)
    }

    func didSelectScope(_ scope: FeedScope) {
        self.scope = scope
        rebuild()
    }

    func didSelectKindFilter(_ filter: FeedKindFilter) {
        guard filter == .all || isPlusActive else {
            router.presentSheet(.paywall)
            return
        }
        kindFilter = filter
        rebuild()
    }

    func didTapRow(id: String) {
        guard let item = items.first(where: { $0.id == id }),
              case .threat(let threat) = item.content,
              situation.threats.contains(where: { $0.id == threat.threatID }) else { return }
        router.showThreatOnMap(id: threat.threatID)
    }

    func didTapReadAloud(id: String) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        dependencies.voiceAnnouncer.read(item)
    }

    func didToggleVoice() {
        dependencies.voiceAnnouncer.setLive(!isVoiceLive)
    }

    func didTapNightReport() {
        router.presentSheet(isPlusActive ? .nightReport : .paywall)
    }

    func didTapHistoryUpsell() {
        router.presentSheet(.paywall)
    }
}

// MARK: - Private methods

private extension FeedViewModel {

    /// Subscribed on the first appearance, not in `init`: the tab's view model is built before the tab is opened.
    func bind() {
        dependencies.feedRepository.itemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
                if self?.isVisible == true {
                    self?.dependencies.feedRepository.markRead(upTo: .now)
                }
                self?.rebuild()
            }
            .store(in: &cancellables)

        dependencies.feedRepository.lastReadAtPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                self?.lastReadAt = date
            }
            .store(in: &cancellables)

        // The distances follow the situation; a second's delay costs nothing and saves rebuilding on every report.
        dependencies.airSituationRepository.situationPublisher
            .throttle(for: Constants.situationThrottle, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] situation in
                self?.situation = situation
                self?.rebuild()
            }
            .store(in: &cancellables)

        bindPlaces()
        bindPlusAndVoice()

        // The feed stops growing once the server refuses this version; say why instead of looking quiet.
        dependencies.realtimeService.connectionStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                upgradeNotice = UpgradeNotice.next(after: upgradeNotice, state: state, appStoreURL: appStoreURL)
            }
            .store(in: &cancellables)

        Timer.publish(every: Constants.refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.rebuild()
            }
            .store(in: &cancellables)
    }

    func bindPlaces() {
        dependencies.watchedPlacesProvider.placesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] places in
                self?.places = places
                self?.rebuild()
            }
            .store(in: &cancellables)

        dependencies.watchedRegionsProvider.regionIDsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] regionIDs in
                self?.regionIDs = regionIDs
                self?.rebuild()
            }
            .store(in: &cancellables)

        dependencies.homeStatusBroadcaster.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.homeStatus = status
            }
            .store(in: &cancellables)
    }

    func bindPlusAndVoice() {
        dependencies.entitlementService.isPlusActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                guard let self else { return }
                isPlusActive = isActive
                if !isActive {
                    kindFilter = .all
                }
                rebuild()
            }
            .store(in: &cancellables)

        dependencies.voiceAnnouncer.isLivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLive in
                self?.isVoiceLive = isLive
            }
            .store(in: &cancellables)

        dependencies.voiceAnnouncer.isSpeakingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSpeaking in
                self?.isSpeaking = isSpeaking
            }
            .store(in: &cancellables)
    }

    func rebuild() {
        let now = Date()
        let places = places
        let threats = Dictionary(situation.threats.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let history = isPlusActive ? PremiumLimits.plusHistory : PremiumLimits.freeHistory
        let historyStart = now.addingTimeInterval(-history)

        var hidden = 0
        var visible: [FeedRow] = []
        var unreadID: String?
        for item in items {
            guard item.isActive || item.updatedAt >= historyStart else {
                hidden += 1
                continue
            }
            let threat = item.threatID.flatMap { threats[$0] }
            guard matchesFilters(item, threat: threat, places: places) else { continue }
            if unreadID == nil, let readAnchor, item.createdAt > readAnchor {
                unreadID = item.id
            }
            visible.append(FeedRow(item: item, threat: threat, places: places, now: now))
        }
        rows = visible
        pinnedRows = visible.filter { $0.isActive && $0.tone == .critical }
        hiddenHistoryCount = hidden
        firstUnreadID = unreadID
        hasNoPlaces = places.isEmpty
    }

    func matchesFilters(
        _ item: FeedItem,
        threat: Threat?,
        places: [WatchedPlace]
    ) -> Bool {
        guard kindFilter.matches(item) else { return false }
        switch scope {
        case .everywhere:
            return true
        case .myPlaces:
            if case .threat(let feedThreat) = item.content, feedThreat.isCountryWide {
                return true
            }
            return !item.regionIDs.isDisjoint(with: regionIDs) || threat?.isNear(places) == true
        }
    }
}

// MARK: - FeedItem

private extension FeedItem {

    var threatID: String? {
        guard case .threat(let threat) = content else { return nil }
        return threat.threatID
    }
}

// MARK: - Constants

private enum Constants {
    static let refreshInterval: TimeInterval = 30
    static let situationThrottle: DispatchQueue.SchedulerTimeType.Stride = .seconds(1)
}
