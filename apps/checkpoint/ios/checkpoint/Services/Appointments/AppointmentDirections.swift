//
//  AppointmentDirections.swift
//  checkpoint
//
//  Directions to a booked shop, in Maps. An appointment's place is described
//  as a GeoToolbox `PlaceDescriptor` (iOS 26) — coordinate and/or address,
//  with the shop as its common name — which MapKit resolves to a map item
//  (`MKMapItemRequest(placeDescriptor:)`, iOS 26). Maps' place card then
//  carries the shop's hours and phone, so Checkpoint doesn't store them.
//
//  With only a shop name on file, a local search for it stands in, and the
//  place it finds is saved back to the appointment so the next tap is exact.
//

import CoreLocation
import Foundation
import GeoToolbox
import MapKit
import os

private let directionsLogger = Logger(category: "AppointmentDirections")

@MainActor
enum AppointmentDirections {

    /// The appointment's place, or nil when only a shop name is on file.
    static func placeDescriptor(for appointment: Appointment) -> PlaceDescriptor? {
        var representations: [PlaceDescriptor.PlaceRepresentation] = []
        if let latitude = appointment.latitude, let longitude = appointment.longitude {
            representations.append(.coordinate(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        }
        if let address = appointment.address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty {
            representations.append(.address(address))
        }
        guard !representations.isEmpty else { return nil }
        return PlaceDescriptor(representations: representations, commonName: appointment.trimmedShopName)
    }

    /// The fields a resolved place writes back: its coordinate and address.
    static func place(from descriptor: PlaceDescriptor) -> (latitude: Double?, longitude: Double?, address: String?) {
        (descriptor.coordinate?.latitude, descriptor.coordinate?.longitude, descriptor.address)
    }

    /// Open Maps with driving directions to the shop. Returns false when
    /// nothing could be found to route to.
    @discardableResult
    static func open(_ appointment: Appointment) async -> Bool {
        guard let item = await mapItem(for: appointment) else { return false }
        if appointment.latitude == nil {
            remember(item, on: appointment)
        }
        return item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    static func mapItem(for appointment: Appointment) async -> MKMapItem? {
        if let descriptor = placeDescriptor(for: appointment) {
            do {
                let item = try await MKMapItemRequest(placeDescriptor: descriptor).mapItem
                if item.name == nil { item.name = appointment.trimmedShopName }
                return item
            } catch {
                directionsLogger.info("Place lookup failed, falling back: \(error.localizedDescription)")
            }
            if let coordinate = descriptor.coordinate {
                let item = MKMapItem(
                    location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                    address: nil
                )
                item.name = appointment.trimmedShopName
                return item
            }
        }
        guard let query = searchQuery(for: appointment) else { return nil }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        do {
            return try await MKLocalSearch(request: request).start().mapItems.first
        } catch {
            directionsLogger.error("Shop search failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// What a local search looks for: the address when there is one, else
    /// the shop's name.
    static func searchQuery(for appointment: Appointment) -> String? {
        if let address = appointment.address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty {
            return address
        }
        return appointment.trimmedShopName
    }

    private static func remember(_ item: MKMapItem, on appointment: Appointment) {
        let coordinate = item.location.coordinate
        appointment.latitude = coordinate.latitude
        appointment.longitude = coordinate.longitude
        if appointment.address == nil, let address = item.address?.fullAddress, !address.isEmpty {
            appointment.address = address
        }
    }
}
