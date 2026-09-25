//
//  WidgetDisplayHelpers.swift
//  CheckpointWidget
//
//  Shared display helpers for every widget family
//

import Foundation

enum WidgetDisplayHelpers {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    /// Format large number with grouping separators
    static func formatNumber(_ number: Int) -> String {
        numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Format mileage in user's preferred unit
    static func formatMileage(_ miles: Int, unit: WidgetDistanceUnit) -> String {
        formatNumber(unit.fromMiles(miles))
    }

    /// Label above the hero value, based on display mode and service type
    static func displayLabel(for service: WidgetService, displayMode: MileageDisplayMode, currentMileage: Int) -> String {
        if let dueMileage = service.dueMileage {
            switch displayMode {
            case .absolute:
                return String(localized: "DUE AT")
            case .relative:
                return currentMileage > dueMileage ? String(localized: "OVERDUE BY") : String(localized: "REMAINING")
            }
        }
        // Date-based items show an abstracted period ("MID MAY"); the period
        // word itself is the value, so the label is just "DUE".
        return service.duePeriod != nil ? String(localized: "DUE") : String(localized: "DUE IN")
    }

    /// The hero value (mileage, period, or days) based on display mode
    static func displayValue(for service: WidgetService, displayMode: MileageDisplayMode, currentMileage: Int, distanceUnit: WidgetDistanceUnit) -> String {
        if let dueMileage = service.dueMileage {
            switch displayMode {
            case .absolute:
                return formatMileage(dueMileage, unit: distanceUnit)
            case .relative:
                return formatMileage(abs(dueMileage - currentMileage), unit: distanceUnit)
            }
        } else if let period = service.duePeriod {
            return period.uppercased()
        } else if let days = service.daysRemaining {
            return "\(abs(days))"
        }
        return "\u{2014}"
    }

    /// Unit beside the hero value
    static func displayUnit(for service: WidgetService, distanceUnit: WidgetDistanceUnit) -> String {
        if service.dueMileage != nil {
            return distanceUnit.uppercaseAbbreviation
        } else if service.duePeriod != nil {
            // The period word ("MID MAY") is the value; no separate unit.
            return ""
        } else if service.daysRemaining != nil {
            return String(localized: "DAYS")
        }
        return ""
    }

    /// Compact due phrase for tight slots (inline, circular): "500 MI",
    /// "500 MI OVER", "MID MAY". Built from the structured fields rather than
    /// by parsing `dueDescription`, which is written in the app's language.
    static func compactDue(for service: WidgetService, currentMileage: Int, distanceUnit: WidgetDistanceUnit) -> String {
        if let dueMileage = service.dueMileage {
            let remaining = dueMileage - currentMileage
            let amount = formatMileage(abs(remaining), unit: distanceUnit)
            let unit = distanceUnit.uppercaseAbbreviation
            return remaining < 0
                ? String(localized: "\(amount) \(unit) OVER")
                : "\(amount) \(unit)"
        }
        if let period = service.duePeriod {
            return period.uppercased()
        }
        return service.dueDescription.uppercased()
    }

    /// "AS OF 3:40 PM" when the snapshot was written on `entryDate`'s day,
    /// "AS OF MAY 3" otherwise. Mileage figures only move when the app writes,
    /// so the widget says how old they are.
    static func asOfLabel(updatedAt: Date, entryDate: Date, calendar: Calendar = .current) -> String {
        let stamp = calendar.isDate(updatedAt, inSameDayAs: entryDate)
            ? updatedAt.formatted(date: .omitted, time: .shortened)
            : updatedAt.formatted(.dateTime.month(.abbreviated).day())
        return String(localized: "AS OF \(stamp)").uppercased()
    }

    /// True once the snapshot predates `entryDate`'s day — the point at which
    /// space-constrained families surface the as-of cue.
    static func isStale(updatedAt: Date, entryDate: Date, calendar: Calendar = .current) -> Bool {
        !calendar.isDate(updatedAt, inSameDayAs: entryDate)
    }
}
