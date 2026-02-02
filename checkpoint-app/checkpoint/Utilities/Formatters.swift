//
//  Formatters.swift
//  checkpoint
//
//  Cached formatters for performance - DateFormatter and NumberFormatter
//  are expensive to create and should be reused.
//

import Foundation

enum Formatters {
    /// Short date format: "Jan 5"
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Medium date format: "Jan 5, 2024"
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    /// Decimal number format: "12,345"
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    /// Currency format: "$45.99"
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    // MARK: - Mileage/Distance Methods

    /// Format mileage with suffix using user's preferred unit: "12,345 mi" or "19,867 km"
    /// Automatically converts from internal miles to user's preferred display unit
    @MainActor
    static func mileage(_ miles: Int) -> String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(miles)
        return (decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)") + " " + unit.abbreviation
    }

    /// Format mileage with underscore suffix (for display): "12,345_MI" or "19,867_KM"
    /// Automatically converts from internal miles to user's preferred display unit
    @MainActor
    static func mileageDisplay(_ miles: Int) -> String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(miles)
        return (decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)") + "_" + unit.uppercaseAbbreviation
    }

    /// Format mileage number only (no suffix): "19,867"
    /// Automatically converts from internal miles to user's preferred display unit
    @MainActor
    static func mileageNumber(_ miles: Int) -> String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(miles)
        return decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)"
    }

    /// Format mileage with explicit unit (for widget/non-MainActor contexts)
    static func mileage(_ miles: Int, unit: DistanceUnit) -> String {
        let displayValue = unit.fromMiles(miles)
        return (decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)") + " " + unit.abbreviation
    }

    /// Format mileage display with explicit unit (for widget/non-MainActor contexts)
    static func mileageDisplay(_ miles: Int, unit: DistanceUnit) -> String {
        let displayValue = unit.fromMiles(miles)
        return (decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)") + "_" + unit.uppercaseAbbreviation
    }

    /// Format mileage number only with explicit unit (for widget/non-MainActor contexts)
    static func mileageNumber(_ miles: Int, unit: DistanceUnit) -> String {
        let displayValue = unit.fromMiles(miles)
        return decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)"
    }

    // MARK: - Estimated Mileage Methods

    /// Format estimated mileage with tilda prefix: "~32,847"
    /// Automatically converts from internal miles to user's preferred display unit
    @MainActor
    static func estimatedMileage(_ miles: Int) -> String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(miles)
        let formatted = decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)"
        return "~" + formatted
    }

    /// Format estimated mileage with explicit unit (for widget/non-MainActor contexts)
    static func estimatedMileage(_ miles: Int, unit: DistanceUnit) -> String {
        let displayValue = unit.fromMiles(miles)
        let formatted = decimal.string(from: NSNumber(value: displayValue)) ?? "\(displayValue)"
        return "~" + formatted
    }
}
