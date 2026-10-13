//
//  PlaceAddressService.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import CoreLocation

/// Reverse geocodes with Apple's geocoder: the coordinate is sent to Apple, nowhere else.
struct PlaceAddressService {

}

// MARK: - PlaceAddressResolving

extension PlaceAddressService: PlaceAddressResolving {

    func address(at coordinate: GeoCoordinate) async -> PlaceAddress? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: Constants.locale).first
        else { return nil }
        let street = [placemark.thoroughfare, placemark.subThoroughfare].compactMap { $0 }.joined(separator: ", ")
        let address = PlaceAddress(locality: placemark.locality, street: street.isEmpty ? nil : street)
        return address.locality == nil && address.street == nil ? nil : address
    }
}

// MARK: - Constants

private enum Constants {
    static let locale = Locale(identifier: "uk_UA")
}
