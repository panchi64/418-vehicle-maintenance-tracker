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

    // MARK: - Date Parsers
    //
    // For parsing fixed-format date strings from external sources (NHTSA API,
    // CSV imports). Locale is en_US_POSIX so user locale doesn't affect parsing,
    // and time zone is UTC so dates round-trip without DST drift.

    /// `MM/dd/yyyy` (e.g. "01/15/2024")
    nonisolated static let dateParserSlashMDY = makeDateParser("MM/dd/yyyy")
    /// `dd/MM/yyyy` (e.g. "27/06/2019")
    nonisolated static let dateParserSlashDMY = makeDateParser("dd/MM/yyyy")
    /// `M/d/yyyy` (e.g. "1/5/2024")
    nonisolated static let dateParserSlashMDYShort = makeDateParser("M/d/yyyy")
    /// `d/M/yyyy` (e.g. "27/6/2019")
    nonisolated static let dateParserSlashDMYShort = makeDateParser("d/M/yyyy")
    /// `yyyy-MM-dd` (e.g. "2024-01-15")
    nonisolated static let dateParserDashYMD = makeDateParser("yyyy-MM-dd")
    /// `yyyy/MM/dd` (e.g. "2024/01/15")
    nonisolated static let dateParserSlashYMD = makeDateParser("yyyy/MM/dd")
    /// `MMM d, yyyy` (e.g. "Jan 5, 2024")
    nonisolated static let dateParserMediumDate = makeDateParser("MMM d, yyyy")

    private nonisolated static func makeDateParser(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    /// Currency format: "$45.99"
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    /// Currency format with no decimals: "$46"
    static let currencyWhole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Format a Decimal as whole-dollar currency: "$1,234"
    static func currencyWhole(_ amount: Decimal) -> String {
        currencyWhole.string(from: amount as NSDecimalNumber) ?? "$0"
    }

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

    // MARK: - Service Interval Formatting

    /// Format a preset's default intervals as a readable string: "6 mo / 5,000 mi"
    @MainActor
    static func serviceInterval(months: Int?, miles: Int?) -> String? {
        let unit = DistanceSettings.shared.unit
        return serviceInterval(months: months, miles: miles, distanceUnit: unit)
    }

    /// Format a preset's default intervals with explicit distance unit
    static func serviceInterval(months: Int?, miles: Int?, distanceUnit: DistanceUnit) -> String? {
        var parts: [String] = []
        if let months = months {
            parts.append("\(months) mo")
        }
        if let miles = miles {
            let displayValue = distanceUnit.fromMiles(miles)
            let formatted = NumberFormatter.localizedString(from: NSNumber(value: displayValue), number: .decimal)
            parts.append("\(formatted) \(distanceUnit.abbreviation)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }
}
