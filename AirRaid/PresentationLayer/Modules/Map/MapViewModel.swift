//
//  MapViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import Foundation
import OSLog

/// The view model that combines static region outlines with the live air situation.
@Observable
final class MapViewModel<Router: MapRouterProtocol>: BaseViewModel {

    // MARK: - Variables

    let styleURL: URL
    private(set) var boundaries: [RegionBoundary] = []
    private(set) var districts: [DistrictBoundary] = []
    private(set) var cities: [City] = []
    private(set) var alertCoverage: AirRaidCoverage = .none
    private(set) var threats: [Threat] = []
    private(set) var connectionNotice: MapConnectionNotice?

    @ObservationIgnored
    private let router: Router

    @ObservationIgnored
    private let regionBoundaryRepository: RegionBoundaryRepositoryProtocol

    @ObservationIgnored
    private let districtBoundaryRepository: DistrictBoundaryRepositoryProtocol

    @ObservationIgnored
    private let cityRepository: CityRepositoryProtocol

    @ObservationIgnored
    private let airSituationRepository: AirSituationRepositoryProtocol

    @ObservationIgnored
    private let realtimeService: RealtimeServiceProtocol

    /// When the connection last went down, so the banner can say how old the map is.
    @ObservationIgnored
    private var liveUntil: Date?

    @ObservationIgnored
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? Constants.subsystem, category: Constants.category)

    init(
        router: Router,
        regionBoundaryRepository: RegionBoundaryRepositoryProtocol,
        districtBoundaryRepository: DistrictBoundaryRepositoryProtocol,
        cityRepository: CityRepositoryProtocol,
        airSituationRepository: AirSituationRepositoryProtocol,
        realtimeService: RealtimeServiceProtocol,
        styleURL: URL
    ) {
        self.router = router
        self.regionBoundaryRepository = regionBoundaryRepository
        self.districtBoundaryRepository = districtBoundaryRepository
        self.cityRepository = cityRepository
        self.airSituationRepository = airSituationRepository
        self.realtimeService = realtimeService
        self.styleURL = styleURL
    }

    // MARK: - Override methods

    override func setupBindings() {
        super.setupBindings()

        airSituationRepository.situationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] situation in
                self?.apply(situation)
            }
            .store(in: &cancellables)

        realtimeService.connectionStatePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.trackLiveness(state)
            }
            .store(in: &cancellables)

        // A reconnect usually takes a second or two; the banner appears only when it takes longer,
        // and disappears as soon as the map is live again.
        realtimeService.connectionStatePublisher
            .removeDuplicates()
            .map { state -> AnyPublisher<RealtimeConnectionState, Never> in
                let current = Just(state)
                guard state != .connected else { return current.eraseToAnyPublisher() }
                return current
                    .delay(for: .seconds(Constants.noticeDelay), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                connectionNotice = MapConnectionNotice(state: state, liveUntil: liveUntil)
            }
            .store(in: &cancellables)
    }
}

// MARK: - MapViewModelProtocol

extension MapViewModel: MapViewModelProtocol {

    var selection: MapSelection? {
        switch router.activeSheet {
        case .threatDetails(let id): .threat(id: id)
        case .regionDetails(let id): .region(id: id)
        case nil: nil
        }
    }

    func onAppear() async {
        if boundaries.isEmpty {
            do {
                boundaries = try await regionBoundaryRepository.fetchBoundaries()
            } catch {
                reportBundledDataFailure(error, resource: "region boundaries")
            }
        }
        if districts.isEmpty {
            do {
                districts = try await districtBoundaryRepository.fetchBoundaries()
            } catch {
                reportBundledDataFailure(error, resource: "raion boundaries")
            }
        }
        if cities.isEmpty {
            do {
                cities = try await cityRepository.fetchRegionalCenters()
            } catch {
                reportBundledDataFailure(error, resource: "regional centers")
            }
        }
    }

    func didSelect(_ selection: MapSelection?) {
        guard let selection else {
            if self.selection != nil {
                router.dismissSheet()
            }
            return
        }
        guard selection != self.selection else { return }
        switch selection {
        case .threat(let id): router.presentSheet(.threatDetails(id: id))
        case .region(let id): router.presentSheet(.regionDetails(id: id))
        }
    }
}

// MARK: - Private methods

private extension MapViewModel {

    func trackLiveness(_ state: RealtimeConnectionState) {
        if state == .connected {
            liveUntil = nil
        } else if liveUntil == nil, !threats.isEmpty || alertCoverage != .none {
            liveUntil = Date()
        }
    }

    func apply(_ situation: AirSituation) {
        alertCoverage = situation.airRaidCoverage
        threats = situation.threats
    }

    /// Map data ships with the app, so a failure here is a build problem, not a user-facing one.
    func reportBundledDataFailure(_ error: Error, resource: String) {
        logger.error("Failed to load \(resource, privacy: .public): \(String(describing: error), privacy: .public)")
        assertionFailure("[MapViewModel] Failed to load \(resource): \(error)")
    }
}

// MARK: - Constants

private enum Constants {
    static let subsystem = "AirRaid"
    static let category = "Map"
    static let noticeDelay: TimeInterval = 3
}
