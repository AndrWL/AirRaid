//
//  HomeStatusBroadcaster.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Combine
import Foundation
import HomeStatusKit
import OSLog

/// Follows the live situation, the home pin and the user's location, and hands the status of the watched place to the
/// widgets and the Live Activity: the home when there is one, otherwise the user's location (with its own radius, as on
/// the map). The location is only known while the app is in use, so the widget keeps the last one.
///
/// Recomputes on every situation or home change (at most once per ``Constants/throttleInterval``) and every
/// ``Constants/forecastInterval``, since the forecast moves threats closer between reports.
///
/// The status is only as fresh as the connection: ``HomeStatusSnapshot/updatedAt`` is the last moment the app was
/// connected, so the widget can tell old data from current. Before the first snapshot from the server nothing is
/// published — the empty initial situation would read as «Тривоги немає».
final class HomeStatusBroadcaster {

    // MARK: - Variables

    private let realtimeService: RealtimeServiceProtocol
    private let airSituationRepository: AirSituationRepositoryProtocol
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol
    private let userLocationService: UserLocationServiceProtocol
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol
    private let districtBoundaryRepository: DistrictBoundaryRepositoryProtocol
    private let widgetPublisher: HomeWidgetPublishing
    private let statusSubject = CurrentValueSubject<HomeStatus?, Never>(nil)
    private let activityController: HomeAlertActivityControlling
    private let liveActivitySettingsService: LiveActivitySettingsServiceProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    private var regions: [RegionBoundary] = []
    private var districts: [DistrictBoundary] = []
    private var situation: AirSituation?
    private var settings: PlaceSettings?
    private var userLocation: GeoCoordinate?
    private var isConnected = false
    private var lastLiveAt: Date?
    private var isStarted = false
    private var cancellables: Set<AnyCancellable> = []

    init(
        realtimeService: RealtimeServiceProtocol,
        airSituationRepository: AirSituationRepositoryProtocol,
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        userLocationService: UserLocationServiceProtocol,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        districtBoundaryRepository: DistrictBoundaryRepositoryProtocol,
        widgetPublisher: HomeWidgetPublishing,
        activityController: HomeAlertActivityControlling,
        liveActivitySettingsService: LiveActivitySettingsServiceProtocol
    ) {
        self.realtimeService = realtimeService
        self.airSituationRepository = airSituationRepository
        self.placeSettingsRepository = placeSettingsRepository
        self.userLocationService = userLocationService
        self.regionBoundaryRepository = regionBoundaryRepository
        self.districtBoundaryRepository = districtBoundaryRepository
        self.widgetPublisher = widgetPublisher
        self.activityController = activityController
        self.liveActivitySettingsService = liveActivitySettingsService
    }
}

// MARK: - HomeStatusBroadcasting

extension HomeStatusBroadcaster: HomeStatusBroadcasting {

    var statusPublisher: AnyPublisher<HomeStatus?, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        // Subscribed at once, so the server's first snapshot is not missed while the outlines load.
        bind()
        Task { [weak self] in
            await self?.loadBoundaries()
        }
    }
}

// MARK: - Private methods

private extension HomeStatusBroadcaster {

    func bind() {
        realtimeService.connectionStatePublisher
            .sink { [weak self] state in
                self?.isConnected = state == .connected
            }
            .store(in: &cancellables)

        // The first value is the repository's empty placeholder, not the server's answer.
        airSituationRepository.situationPublisher
            .dropFirst()
            .throttle(for: Constants.throttleInterval, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] situation in
                // A message from the server is live by definition, even before the connection reports `connected`
                // (the client confirms it with the first pong, which comes after the snapshot).
                self?.situation = situation
                self?.lastLiveAt = Date()
                self?.refresh()
            }
            .store(in: &cancellables)

        placeSettingsRepository.settingsPublisher
            .removeDuplicates()
            .sink { [weak self] settings in
                self?.settings = settings
                self?.refresh()
            }
            .store(in: &cancellables)

        // A lost fix (permission revoked) keeps nothing: the place is gone, not stale.
        userLocationService.locationPublisher
            .removeDuplicates()
            .sink { [weak self] location in
                self?.userLocation = location
                self?.refresh()
            }
            .store(in: &cancellables)

        // Turned back on, the activity starts at once for an alert or a threat that is already there.
        liveActivitySettingsService.isEnabledPublisher
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.activityController.setEnabled(isEnabled)
                self?.refresh()
            }
            .store(in: &cancellables)

        Timer.publish(every: Constants.forecastInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    /// Without the outlines the home's oblast is unknown and every alert would be missed, so nothing is published.
    func loadBoundaries() async {
        do {
            regions = try await regionBoundaryRepository.fetchBoundaries()
            districts = try await districtBoundaryRepository.fetchBoundaries()
        } catch {
            logger.error("Failed to load outlines: \(String(describing: error), privacy: .public)")
            return
        }
        refresh()
    }

    func refresh() {
        guard let settings, !regions.isEmpty else { return }
        let now = Date()
        if isConnected {
            lastLiveAt = now
        }
        // The home wins; the location stands in only while there is no home, as the map's second place.
        let places = WatchedPlace.places(currentLocation: userLocation, settings: settings)
        guard let place = places.first(where: { $0.kind == .home }) ?? places.first else {
            // Losing every place needs no server data.
            publish(nil, updatedAt: lastLiveAt ?? now)
            return
        }
        guard let situation, let lastLiveAt else { return }
        let status = HomeStatusFactory.make(
            place: place,
            situation: situation,
            regions: regions,
            districts: districts,
            now: now
        )
        publish(status, updatedAt: lastLiveAt)
    }

    func publish(
        _ status: HomeStatus?,
        updatedAt: Date
    ) {
        statusSubject.send(status)
        widgetPublisher.publish(HomeStatusSnapshot(updatedAt: updatedAt, home: status))
        activityController.update(with: status, updatedAt: updatedAt)
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "HomeStatus"
    static let throttleInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(1)
    static let forecastInterval: TimeInterval = 60
}
