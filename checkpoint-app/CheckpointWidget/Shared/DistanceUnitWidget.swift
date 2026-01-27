//
//  DistanceUnitWidget.swift
//  CheckpointWidget
//
//  Lightweight distance unit helper for widget - reads from shared App Group
//

import Foundation

enum WidgetDistanceUnit: String, CaseIterable {
    case miles
    case kilometers

    // MARK: - Constants

    static let kmPerMile = 1.60934

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

    /// Full name: "miles" or "kilometers"
    var fullName: String {
        rawValue
    }

    // MARK: - Conversion

    /// Convert stored miles to display value
    func fromMiles(_ miles: Int) -> Int {
        switch self {
        case .miles:
            return miles
        case .kilometers:
            return Int(round(Double(miles) * Self.kmPerMile))
        }
    }

    // MARK: - App Group Access

    private static let appGroupID = "group.com.418-studio.checkpoint.shared"
    private static let unitKey = "distanceUnit"

    /// Read distance unit from shared App Group UserDefaults
    static func current() -> WidgetDistanceUnit {
        let rawValue = UserDefaults(suiteName: appGroupID)?.string(forKey: unitKey)
        return rawValue.flatMap(WidgetDistanceUnit.init(rawValue:)) ?? .miles
    }
}
