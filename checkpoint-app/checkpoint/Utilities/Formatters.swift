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

    // MARK: - Convenience Methods

    /// Format mileage with suffix: "12,345 mi"
    static func mileage(_ miles: Int) -> String {
        (decimal.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }

    /// Format mileage with underscore suffix (for display): "12,345_MI"
    static func mileageDisplay(_ miles: Int) -> String {
        (decimal.string(from: NSNumber(value: miles)) ?? "\(miles)") + "_MI"
    }
}
