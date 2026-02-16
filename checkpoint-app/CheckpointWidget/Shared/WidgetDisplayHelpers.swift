//
//  WidgetDisplayHelpers.swift
//  CheckpointWidget
//
//  Shared display helper methods for Small and Medium widget views
//  Consolidates duplicated formatting logic
//

import Foundation

/// Shared formatting helpers used by both SmallWidgetView and MediumWidgetView
enum WidgetDisplayHelpers {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    /// Format large number with comma separators
    static func formatNumber(_ number: Int) -> String {
        numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Format mileage in user's preferred unit
    static func formatMileage(_ miles: Int, unit: WidgetDistanceUnit) -> String {
        let displayValue = unit.fromMiles(miles)
        return formatNumber(displayValue)
    }

    /// Get the label text based on display mode and service type
    static func displayLabel(for service: WidgetService, displayMode: MileageDisplayMode, currentMileage: Int) -> String {
        if service.dueMileage != nil {
            switch displayMode {
            case .absolute:
                return "DUE AT"
            case .relative:
                if let dueMileage = service.dueMileage, currentMileage > dueMileage {
                    return "OVERDUE BY"
                }
                return "REMAINING"
            }
        }
        return "DUE IN"
    }

    /// Get the display value (mileage or days) based on display mode
    static func displayValue(for service: WidgetService, displayMode: MileageDisplayMode, currentMileage: Int, distanceUnit: WidgetDistanceUnit) -> String {
        if let dueMileage = service.dueMileage {
            switch displayMode {
            case .absolute:
                return formatMileage(dueMileage, unit: distanceUnit)
            case .relative:
                let remaining = dueMileage - currentMileage
                return formatMileage(abs(remaining), unit: distanceUnit)
            }
        } else if let days = service.daysRemaining {
            return "\(abs(days))"
        }
        return "\u{2014}"
    }

    /// Get the unit label based on what we're displaying
    static func displayUnit(for service: WidgetService, distanceUnit: WidgetDistanceUnit) -> String {
        if service.dueMileage != nil {
            return distanceUnit.uppercaseAbbreviation
        } else if service.daysRemaining != nil {
            return "DAYS"
        }
        return ""
    }

    /// Get status label text
    static func statusLabel(for status: WidgetServiceStatus) -> String {
        switch status {
        case .overdue: return "OVERDUE"
        case .dueSoon: return "DUE SOON"
        case .good: return "GOOD"
        case .neutral: return ""
        }
    }
}
