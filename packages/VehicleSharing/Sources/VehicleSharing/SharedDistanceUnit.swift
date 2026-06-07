//
//  SharedDistanceUnit.swift
//  VehicleSharing
//
//  Minimal distance unit for the cross-app wire format. Raw values match
//  Checkpoint's `DistanceUnit` so the two map 1:1 by rawValue.
//

import Foundation

/// Distance unit carried alongside shared odometer readings so the reading app
/// (Biombo) can display and accept input in the user's preferred unit. All
/// stored mileage values are in miles; this unit governs display/input only.
public enum SharedDistanceUnit: String, Codable, Sendable, CaseIterable {
    case miles
    case kilometers

    static let kmPerMile = 1.60934
    static let milesPerKm = 0.621371

    /// Short abbreviation: "mi" or "km".
    public var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    /// Convert stored miles into this unit for display.
    public func fromMiles(_ miles: Int) -> Int {
        switch self {
        case .miles: return miles
        case .kilometers: return Int((Double(miles) * Self.kmPerMile).rounded())
        }
    }

    /// Convert a value entered in this unit back into miles for storage.
    public func toMiles(_ value: Int) -> Int {
        switch self {
        case .miles: return value
        case .kilometers: return Int((Double(value) * Self.milesPerKm).rounded())
        }
    }
}
