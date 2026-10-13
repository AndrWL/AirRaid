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
    private(set) var focusedRegionID: String?
    private(set) var recenterRequest = 0
    private(set) var userLocation: GeoCoordinate?
    private(set) var nearThreatIDs: Set<String> = []
    private(set) var nearThreatAlertCount = 0
    private(set) var placeSettings: PlaceSettings = .initial
    private(set) var isPickingHome = false
    private(set) var locationAuthorization: LocationAuthorization = .notDetermined
    private(set) var flyRequest: MapFlyRequest?
    private(set) var isLocationDeniedAlertPresented = false

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

    @ObservationIgnored
    private let focusedRegionRepository: FocusedRegionRepositoryProtocol

    @ObservationIgnored
    private let userLocationService: UserLocationServiceProtocol

    @ObservationIgnored
    private let placeSettingsRepository: PlaceSettingsRepositoryProtocol

    @ObservationIgnored
    private let alertSoundService: AlertSoundServiceProtocol

    /// Threats already announced by a sound, so one that stays near is announced once, not on every update.
    @ObservationIgnored
    private var announcedThreatIDs: Set<String> = []

    /// "To me" was tapped before there was a fix; the camera flies once the first one arrives.
    @ObservationIgnored
    private var isLocatePending = false

    /// The point under the centre of the map, followed while picking the home; ignored for observation because it
    /// changes on every pan and nothing renders from it.
    @ObservationIgnored
    private var mapCenter: GeoCoordinate?

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
        focusedRegionRepository: FocusedRegionRepositoryProtocol,
        userLocationService: UserLocationServiceProtocol,
        placeSettingsRepository: PlaceSettingsRepositoryProtocol,
        alertSoundService: AlertSoundServiceProtocol,
        styleURL: URL
    ) {
        self.router = router
        self.regionBoundaryRepository = regionBoundaryRepository
        self.districtBoundaryRepository = districtBoundaryRepository
        self.cityRepository = cityRepository
        self.airSituationRepository = airSituationRepository
        self.realtimeService = realtimeService
        self.focusedRegionRepository = focusedRegionRepository
        self.userLocationService = userLocationService
        self.placeSettingsRepository = placeSettingsRepository
        self.alertSoundService = alertSoundService
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

        bindPreferences()
        bindUserLocation()

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
        case .homeDetails: .home
        case .places, nil: nil
        }
    }

    var focusedRegionName: String? {
        focusedRegionID.flatMap { id in boundaries.first { $0.id == id }?.name }
    }

    func didTapRecenter() {
        recenterRequest += 1
    }

    var places: [WatchedPlace] {
        WatchedPlace.places(currentLocation: userLocation, settings: placeSettings)
    }

    func placeThreats(at date: Date) -> [NearestThreatSummary] {
        NearestThreatSummary.nearest(among: threats, places: places, at: date)
    }

    func didTapPlaces() {
        router.presentSheet(.places)
    }

    func didStartPickingHome() {
        router.dismissSheet()
        isPickingHome = true
        // Start where the user is most likely to put it: the current home, else where they are now.
        if let start = placeSettings.home?.coordinate ?? userLocation {
            fly(to: start)
        }
    }

    func didChangeMapCenter(_ center: GeoCoordinate) {
        mapCenter = center
    }

    func didConfirmHomePick() {
        if let mapCenter {
            placeSettingsRepository.setHome(at: mapCenter)
        }
        isPickingHome = false
    }

    func didCancelHomePick() {
        isPickingHome = false
    }

    func didTapLocate() {
        switch locationAuthorization {
        case .notDetermined:
            isLocatePending = true
            userLocationService.requestAuthorization()
        case .denied:
            isLocationDeniedAlertPresented = true
        case .authorized:
            if let userLocation {
                fly(to: userLocation)
            } else {
                isLocatePending = true
            }
        }
    }

    func didDismissLocationDeniedAlert() {
        isLocationDeniedAlertPresented = false
    }

    func didTapExitFocus() {
        focusedRegionRepository.setFocusedRegion(nil)
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
        // While picking the home, taps belong to placing it.
        guard !isPickingHome else { return }
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
        case .home: router.presentSheet(.homeDetails)
        }
    }
}

// MARK: - Private methods

private extension MapViewModel {

    /// The followed and the focused regions, which the region sheet changes.
    func bindPreferences() {
        focusedRegionRepository.focusedRegionIDPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.focusedRegionID = id
            }
            .store(in: &cancellables)
    }

    func bindUserLocation() {
        placeSettingsRepository.settingsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.placeSettings = settings
                self?.updateNearThreats()
            }
            .store(in: &cancellables)

        userLocationService.authorizationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorization in
                self?.locationAuthorization = authorization
            }
            .store(in: &cancellables)

        userLocationService.locationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.apply(location)
            }
            .store(in: &cancellables)
    }

    func trackLiveness(_ state: RealtimeConnectionState) {
        if state == .connected {
            liveUntil = nil
        } else if liveUntil == nil, !threats.isEmpty || alertCoverage != .none {
            liveUntil = Date()
        }
    }

    func apply(_ location: GeoCoordinate?) {
        userLocation = location
        if let location, isLocatePending {
            isLocatePending = false
            fly(to: location)
        }
        updateNearThreats()
    }

    func fly(to coordinate: GeoCoordinate) {
        flyRequest = MapFlyRequest(id: (flyRequest?.id ?? 0) + 1, coordinate: coordinate)
    }

    func apply(_ situation: AirSituation) {
        alertCoverage = situation.airRaidCoverage
        threats = situation.threats
        updateNearThreats()
    }

    /// Marks the threats inside a place's radius and sounds once for each that has just come in.
    func updateNearThreats() {
        let places = places
        let near = Set(threats.filter { $0.isNear(places) }.map(\.id))
        if near != nearThreatIDs {
            nearThreatIDs = near
        }
        let new = near.subtracting(announcedThreatIDs)
        if !new.isEmpty {
            alertSoundService.playThreatNearby()
            nearThreatAlertCount += 1
        }
        // Forget threats that left, so one that comes back is announced again.
        announcedThreatIDs = near
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
