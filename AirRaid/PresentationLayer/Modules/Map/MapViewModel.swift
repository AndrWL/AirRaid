//
//  MapViewModel.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 07.10.2026.
//

import Combine
import Foundation
import OSLog
import UIKit

/// The view model that combines static region outlines with the live air situation.
@Observable
final class MapViewModel<Router: MapRouterProtocol>: BaseViewModel {

    // MARK: - Variables

    let appStoreURL: URL?
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
    private(set) var places: [WatchedPlace] = []
    private(set) var placePick: PlacePick?
    private(set) var placePickConfirmCount = 0
    var namingPlaceID: SavedPlace.ID?
    private(set) var locationAuthorization: LocationAuthorization = .notDetermined
    private(set) var flyRequest: MapFlyRequest?
    private(set) var mapStylePreference: MapStylePreference = .system
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
    private let watchedPlacesProvider: WatchedPlacesProviding

    @ObservationIgnored
    private let alertSoundService: AlertSoundServiceProtocol

    @ObservationIgnored
    private let mapStyleSettingsService: MapStyleSettingsServiceProtocol

    /// Threats already announced by a sound, so one that stays near is announced once, not on every update.
    @ObservationIgnored
    private var announcedThreatIDs: Set<String> = []

    /// "To me" was tapped before there was a fix; the camera flies once the first one arrives.
    @ObservationIgnored
    private var isLocatePending = false

    /// The camera has not yet been put on the user or their home since launch; until then it shows the country.
    @ObservationIgnored
    private var isInitialCameraPending = true

    /// Location permission is read asynchronously; until it is known, a home is not chosen over a fix still to come.
    @ObservationIgnored
    private var isAuthorizationKnown = false

    /// Past this moment the user has had the map to themselves, so a late fix or home no longer moves it.
    @ObservationIgnored
    private let initialCameraDeadline = Date().addingTimeInterval(Constants.initialCameraTimeout)

    /// The point under the centre of the map, followed while picking a place; ignored for observation because it
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
        watchedPlacesProvider: WatchedPlacesProviding,
        alertSoundService: AlertSoundServiceProtocol,
        mapStyleSettingsService: MapStyleSettingsServiceProtocol,
        appStoreURL: URL?
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
        self.watchedPlacesProvider = watchedPlacesProvider
        self.alertSoundService = alertSoundService
        self.mapStyleSettingsService = mapStyleSettingsService
        self.appStoreURL = appStoreURL
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

        mapStyleSettingsService.preferencePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preference in
                self?.mapStylePreference = preference
            }
            .store(in: &cancellables)

        bindPreferences()
        bindUserLocation()

        router.intentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] intent in
                self?.handle(intent)
            }
            .store(in: &cancellables)

        // A reconnect usually takes a second or two; the banner appears only when it takes longer,
        // and disappears as soon as the map is live again. A refused version is final, so it shows at once.
        realtimeService.connectionStatePublisher
            .removeDuplicates()
            .map { state -> AnyPublisher<RealtimeConnectionState, Never> in
                let current = Just(state)
                guard state != .connected, state != .upgradeRequired else { return current.eraseToAnyPublisher() }
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

        // The connection is closed in the background on purpose, and the delayed banner may have come up meanwhile;
        // back in the foreground the reconnect gets its own grace period instead of showing that stale banner.
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self, connectionNotice != .upgradeRequired else { return }
                connectionNotice = nil
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
        case .placeDetails(let id): .place(id: id)
        case .places, .legend, nil: nil
        }
    }

    var focusedRegionName: String? {
        focusedRegionID.flatMap { id in boundaries.first { $0.id == id }?.name }
    }

    func didTapRecenter() {
        recenterRequest += 1
    }

    func placeThreats(at date: Date) -> [NearestThreatSummary] {
        NearestThreatSummary.nearest(among: threats, places: places, at: date)
    }

    func didTapPlaces() {
        router.presentSheet(.places)
    }

    func didTapLegend() {
        router.presentSheet(.legend)
    }

    func didStartPicking(_ pick: PlacePick) {
        router.dismissSheet()
        placePick = pick
        // Start where the user is most likely to put it: where the place is now, else where they are.
        let current: GeoCoordinate? = switch pick {
        case .home: placeSettings.home?.coordinate
        case .newPlace: nil
        case .move(let id): placeSettings.place(id: id)?.coordinate
        }
        if let start = current ?? userLocation {
            fly(to: start)
        }
    }

    func didChangeMapCenter(_ center: GeoCoordinate) {
        mapCenter = center
    }

    func didConfirmPlacePick() {
        defer { placePick = nil }
        guard let mapCenter, let placePick else { return }
        switch placePick {
        case .home:
            placeSettingsRepository.setHome(at: mapCenter)
        case .newPlace:
            // Saved at once under its locality; the name the user gives next replaces it.
            namingPlaceID = placeSettingsRepository.addPlace(at: mapCenter, name: nil)
        case .move(let id):
            placeSettingsRepository.movePlace(id, to: mapCenter)
        }
        placePickConfirmCount += 1
    }

    func didCancelPlacePick() {
        placePick = nil
    }

    func didNamePlace(_ name: String) {
        guard let namingPlaceID else { return }
        placeSettingsRepository.renamePlace(namingPlaceID, to: name)
        self.namingPlaceID = nil
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
        // While picking a place, taps belong to placing it.
        guard placePick == nil else { return }
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
        case .place(let id): router.presentSheet(.placeDetails(id: id))
        }
    }

    func didTapPlaceThreatBanner(threatID: String) {
        guard placePick == nil else { return }
        showThreat(id: threatID)
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
            }
            .store(in: &cancellables)

        watchedPlacesProvider.placesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] places in
                self?.places = places
                self?.updateNearThreats()
                self?.updateInitialCamera()
            }
            .store(in: &cancellables)

        userLocationService.authorizationPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorization in
                self?.locationAuthorization = authorization
                self?.isAuthorizationKnown = true
                self?.updateInitialCamera()
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
            isInitialCameraPending = false
            fly(to: location)
        }
        updateNearThreats()
        updateInitialCamera()
    }

    /// At launch, puts the camera on the user's location, or on their home when location is not allowed; a focused
    /// region keeps its own fit. Once only, and only in the first seconds, so a late fix does not yank a map the user
    /// is already looking at.
    func updateInitialCamera() {
        guard isInitialCameraPending else { return }
        guard focusedRegionID == nil, placePick == nil, selection == nil, Date() < initialCameraDeadline else {
            isInitialCameraPending = false
            return
        }
        if let userLocation {
            isInitialCameraPending = false
            fly(to: userLocation)
            return
        }
        // While location is allowed, the first fix is on its way and wins over the home.
        guard isAuthorizationKnown, locationAuthorization != .authorized,
              let home = places.first(where: { $0.kind == .home }) else { return }
        isInitialCameraPending = false
        fly(to: home.coordinate)
    }

    func fly(to coordinate: GeoCoordinate) {
        flyRequest = MapFlyRequest(id: (flyRequest?.id ?? 0) + 1, coordinate: coordinate)
    }

    func apply(_ situation: AirSituation) {
        alertCoverage = situation.airRaidCoverage
        threats = situation.threats
        updateNearThreats()
    }

    func handle(_ intent: MapIntent) {
        switch intent {
        case .pickPlace(let pick):
            didStartPicking(pick)
        case .showThreat(let id):
            showThreat(id: id)
        }
    }

    /// Flies to the threat's pin, where the map draws it, and opens its sheet.
    func showThreat(id: String) {
        let coordinate = threats.first { $0.id == id }?.markerCoordinate(coverage: alertCoverage, districts: districts)
        logger.debug("Show threat \(id, privacy: .public): on map \(coordinate != nil), sheet \(String(describing: self.router.activeSheet), privacy: .public)")
        if let coordinate {
            fly(to: coordinate)
        }
        router.presentSheet(.threatDetails(id: id))
    }

    /// Marks the threats inside a place's radius and sounds once for each that has just come in.
    func updateNearThreats() {
        let places = places
        let near = Set(threats.filter { $0.isNear(places) }.map(\.id))
        if near != nearThreatIDs {
            nearThreatIDs = near
        }
        let new = near.subtracting(announcedThreatIDs)
        // The haptic follows the sound, so "off" in the settings silences both.
        if !new.isEmpty, alertSoundService.playThreatNearby() {
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
    static let initialCameraTimeout: TimeInterval = 5
}
