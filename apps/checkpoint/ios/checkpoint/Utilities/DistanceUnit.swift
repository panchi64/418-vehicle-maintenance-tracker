//
//  DistanceUnit.swift
//  checkpoint
//
//  Distance unit enum with conversion logic for miles/kilometers support
//  Also compiled into the Watch app — keep it free of iOS-only dependencies
//  (localized names live in DistanceUnit+Localized.swift)
//

import Foundation

enum DistanceUnit: String, CaseIterable, Codable {
    case miles
    case kilometers

    // MARK: - Constants

    static let kmPerMile = 1.60934
    static let milesPerKm = 0.621371

    // MARK: - Display Properties

    /// Short abbreviation: "mi" or "km"
    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    /// Uppercase abbreviation: "MI" or "KM"
    var uppercaseAbbreviation: String {
        abbreviation.uppercased()
    }

    // MARK: - Conversion Methods

    /// Convert stored miles to display value
    /// - Parameter miles: Value in miles (internal storage format)
    /// - Returns: Value in user's preferred unit
    func fromMiles(_ miles: Int) -> Int {
        switch self {
        case .miles:
            return miles
        case .kilometers:
            return Int(round(Double(miles) * Self.kmPerMile))
        }
    }

    /// Convert stored miles (Double) to display value
    /// - Parameter miles: Value in miles (internal storage format)
    /// - Returns: Value in user's preferred unit
    func fromMiles(_ miles: Double) -> Double {
        switch self {
        case .miles:
            return miles
        case .kilometers:
            return miles * Self.kmPerMile
        }
    }

    /// Convert user input to miles for storage
    /// - Parameter value: Value in user's preferred unit
    /// - Returns: Value in miles (internal storage format)
    func toMiles(_ value: Int) -> Int {
        switch self {
        case .miles:
            return value
        case .kilometers:
            return Int(round(Double(value) * Self.milesPerKm))
        }
    }

    /// Convert user input (Double) to miles for storage
    /// - Parameter value: Value in user's preferred unit
    /// - Returns: Value in miles (internal storage format)
    func toMiles(_ value: Double) -> Double {
        switch self {
        case .miles:
            return value
        case .kilometers:
            return value * Self.milesPerKm
        }
    }
}
