//
//  SeasonalReminder.swift
//  checkpoint
//
//  Seasonal maintenance reminder definitions and active filtering logic
//

import Foundation

struct SeasonalReminder: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let targetMonth: Int
    let displayWindow: Int
    let climateZones: Set<ClimateZone>
    let category: ServiceCategory

    // MARK: - Catalog

    static let allReminders: [SeasonalReminder] = [
        SeasonalReminder(
            id: "antifreeze",
            name: "Antifreeze Check",
            description: "Check antifreeze levels before winter sets in.",
            icon: "thermometer.snowflake",
            targetMonth: 10,
            displayWindow: 30,
            climateZones: [.coldWinter],
            category: .fluids
        ),
        SeasonalReminder(
            id: "winterTires",
            name: "Winter Tire Swap",
            description: "Time to switch to winter tires?",
            icon: "tire",
            targetMonth: 10,
            displayWindow: 30,
            climateZones: [.coldWinter],
            category: .tires
        ),
        SeasonalReminder(
            id: "summerTires",
            name: "Summer Tire Swap",
            description: "Roads are clearing up — time for summer tires.",
            icon: "tire",
            targetMonth: 3,
            displayWindow: 30,
            climateZones: [.coldWinter],
            category: .tires
        ),
        SeasonalReminder(
            id: "saltDamage",
            name: "Undercarriage Inspection",
            description: "Check for salt damage and rust underneath.",
            icon: "car.side",
            targetMonth: 3,
            displayWindow: 14,
            climateZones: [.coldWinter],
            category: .body
        ),
        SeasonalReminder(
            id: "acSystem",
            name: "AC System Check",
            description: "Make sure your AC is ready for the heat.",
            icon: "snowflake",
            targetMonth: 4,
            displayWindow: 30,
            climateZones: [.hotDry, .hotHumid, .mildFourSeason],
            category: .electrical
        ),
        SeasonalReminder(
            id: "wiperBlades",
            name: "Wiper Blade Check",
            description: "Rain season approaching — check your wipers.",
            icon: "wiper.washer.fluid.and.wiper",
            targetMonth: 9,
            displayWindow: 14,
            climateZones: [.mildFourSeason, .hotHumid, .tropical],
            category: .body
        ),
        SeasonalReminder(
            id: "batteryHeat",
            name: "Battery Check",
            description: "Extreme heat drains batteries — check yours.",
            icon: "minus.plus.batteryblock",
            targetMonth: 5,
            displayWindow: 30,
            climateZones: [.hotDry],
            category: .electrical
        ),
        SeasonalReminder(
            id: "coolantSummer",
            name: "Coolant Level Check",
            description: "Top off coolant before peak summer temperatures.",
            icon: "drop.fill",
            targetMonth: 5,
            displayWindow: 14,
            climateZones: [.hotDry, .hotHumid],
            category: .fluids
        ),
    ]

    // MARK: - Active Filtering

    /// Returns reminders that are currently active for the given zone and date.
    /// Respects SeasonalSettings for enabled state, dismissals, and suppressions.
    @MainActor
    static func activeReminders(for zone: ClimateZone?, on date: Date, settings: SeasonalSettings = .shared) -> [SeasonalReminder] {
        guard settings.isEnabled, let zone = zone else { return [] }

        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        return allReminders.filter { reminder in
            // Must apply to this zone
            guard reminder.climateZones.contains(zone) else { return false }

            // Must not be permanently suppressed
            guard !settings.isSuppressed(reminder.id) else { return false }

            // Must not be dismissed for this year
            guard !settings.isDismissed(reminder.id, year: year) else { return false }

            // Must be within the display window
            return reminder.isWithinDisplayWindow(on: date, calendar: calendar)
        }
    }

    /// Build pre-fill data for creating a tracked service from this reminder.
    func toPrefill() -> SeasonalPrefill {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        var components = DateComponents()
        components.year = year
        components.month = targetMonth
        components.day = 1
        let dueDate = calendar.date(from: components) ?? Date()

        return SeasonalPrefill(
            reminderID: id,
            serviceName: name,
            dueDate: dueDate,
            intervalMonths: 12
        )
    }

    /// Check if the reminder should be shown on a given date.
    /// Active from `displayWindow` days before the 1st of `targetMonth` through end of `targetMonth`.
    func isWithinDisplayWindow(on date: Date, calendar: Calendar = .current) -> Bool {
        let year = calendar.component(.year, from: date)

        // Build the 1st of target month in this year
        var targetComponents = DateComponents()
        targetComponents.year = year
        targetComponents.month = targetMonth
        targetComponents.day = 1
        guard let targetStart = calendar.date(from: targetComponents) else { return false }

        // Window start: displayWindow days before the 1st of target month
        guard let windowStart = calendar.date(byAdding: .day, value: -displayWindow, to: targetStart) else { return false }

        // Window end: last day of target month
        guard let targetEnd = calendar.date(byAdding: .month, value: 1, to: targetStart),
              let windowEnd = calendar.date(byAdding: .day, value: -1, to: targetEnd) else { return false }

        return date >= windowStart && date <= windowEnd
    }
}

// MARK: - Pre-fill Data

/// Data for pre-filling AddServiceView from a seasonal reminder
struct SeasonalPrefill {
    let reminderID: String
    let serviceName: String
    let dueDate: Date
    let intervalMonths: Int
}
