//
//  UserLocationService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 12.10.2026.
//

import Combine
import CoreLocation

/// Follows the user's location with Core Location, "when in use" only.
///
/// City-block accuracy is enough to measure the distance to a threat, and it is cheaper on the battery than GPS.
final class UserLocationService: NSObject {

    // MARK: - Variables

    private let manager: CLLocationManager
    private let authorizationSubject: CurrentValueSubject<LocationAuthorization, Never>
    private let locationSubject = CurrentValueSubject<GeoCoordinate?, Never>(nil)

    init(
        manager: CLLocationManager = CLLocationManager()
    ) {
        self.manager = manager
        self.authorizationSubject = CurrentValueSubject(Self.map(manager.authorizationStatus))
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = Constants.distanceFilter
        manager.delegate = self
        updateMonitoring()
    }
}

// MARK: - UserLocationServiceProtocol

extension UserLocationService: UserLocationServiceProtocol {

    var authorizationPublisher: AnyPublisher<LocationAuthorization, Never> {
        authorizationSubject.eraseToAnyPublisher()
    }

    var locationPublisher: AnyPublisher<GeoCoordinate?, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    func requestAuthorization() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }
}

// MARK: - CLLocationManagerDelegate

/// The manager is created on the main thread, so it calls back on it.
extension UserLocationService: @preconcurrency CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationSubject.send(Self.map(manager.authorizationStatus))
        updateMonitoring()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationSubject.send(GeoCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
    }

    /// A failed fix keeps the last known location: it is still the best guess.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

// MARK: - Private methods

private extension UserLocationService {

    func updateMonitoring() {
        if authorizationSubject.value == .authorized {
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
            locationSubject.send(nil)
        }
    }

    static func map(_ status: CLAuthorizationStatus) -> LocationAuthorization {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }
}

// MARK: - Constants

private enum Constants {
    /// Metres the user must move before a new fix is reported.
    static let distanceFilter: CLLocationDistance = 500
}
