//
//  StarterSchedule.swift
//  checkpoint
//
//  The services offered right after a vehicle is added, and how each one's
//  first reminder is derived from what the user remembers about it. Pure: the
//  sheet (`StarterScheduleSheet`) owns persistence and notifications.
//
//  WHY. A new vehicle with no services is an empty app next to a used car —
//  nothing is due, so nothing reminds. Most owners can't reconstruct their
//  history, but they can accept sensible defaults in one tap.
//
//  DERIVATION, per dimension. A service's next due date anchors on the date it
//  was last done when the user knows it, otherwise on today; its due mileage
//  anchors on the odometer reading at the last service when known, otherwise
//  on the current reading. So "Don't know" means "start counting now", and a
//  known date still gets a mileage backstop. Both go through
//  `ReminderImpactCalculator.projected`, the save path every form uses (F4).
//

import Foundation

/// What the user remembers about when a service was last done.
enum StarterLastDone: Equatable {
    case unknown
    case date(Date)
    case mileage(Int)

    /// The three choices the row offers, without their values.
    enum Kind: CaseIterable, Hashable {
        case unknown, date, mileage
    }

    var kind: Kind {
        switch self {
        case .unknown: return .unknown
        case .date: return .date
        case .mileage: return .mileage
        }
    }
}

struct StarterScheduleItem: Identifiable, Equatable {
    let name: String
    let category: String
    let intervalMonths: Int?
    let intervalMiles: Int?
    var isIncluded = true
    var lastDone: StarterLastDone = .unknown

    var id: String { name }

    /// A mileage anchor means nothing for a service with no mileage interval
    /// (battery check, wiper blades), so the row doesn't offer it.
    var offersMileage: Bool { (intervalMiles ?? 0) > 0 }
}

enum StarterSchedule {
    /// The common services for a car, in the order the sheet lists them. Only
    /// names the bundled preset catalog carries are offered, with its
    /// intervals.
    static let commonServiceNames = [
        "Oil Change",
        "Tire Rotation",
        "Brake Inspection",
        "Air Filter",
        "Cabin Air Filter",
        "Battery Check",
        "Wiper Blades",
    ]

    /// The starter list: common presets that have an interval, minus any the
    /// vehicle already tracks.
    static func items(from presets: [PresetData], excluding existingNames: [String] = []) -> [StarterScheduleItem] {
        let existing = Set(existingNames.map { $0.lowercased() })
        return commonServiceNames.compactMap { name in
            guard !existing.contains(name.lowercased()),
                  let preset = presets.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }),
                  Service.hasIntervalPolicy(intervalMonths: preset.defaultIntervalMonths,
                                            intervalMiles: preset.defaultIntervalMiles)
            else { return nil }
            return StarterScheduleItem(
                name: preset.name,
                category: preset.category,
                intervalMonths: preset.defaultIntervalMonths,
                intervalMiles: preset.defaultIntervalMiles
            )
        }
    }

    /// Everything the sheet writes for one service.
    struct Plan: Equatable {
        let name: String
        let intervalMonths: Int?
        let intervalMiles: Int?
        let dueDate: Date?
        let dueMileage: Int?
        let lastPerformed: Date?
        let lastMileage: Int?
    }

    static func plan(for item: StarterScheduleItem, currentMileage: Int, now: Date = .now) -> Plan {
        var lastPerformed: Date?
        var lastMileage: Int?
        switch item.lastDone {
        case .unknown:
            break
        case .date(let date):
            // A future "last done" is a slip of the picker, not a plan.
            lastPerformed = min(date, now)
        case .mileage(let mileage) where item.offersMileage:
            // Last done above the current odometer would schedule the next one
            // further out than the interval allows.
            lastMileage = min(max(mileage, 0), currentMileage)
        case .mileage:
            break
        }

        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: item.intervalMonths,
            intervalMiles: item.intervalMiles,
            anchorDate: lastPerformed ?? now,
            anchorMileage: lastMileage ?? currentMileage,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )

        return Plan(
            name: item.name,
            intervalMonths: item.intervalMonths,
            intervalMiles: item.intervalMiles,
            dueDate: schedule.dueDate,
            dueMileage: schedule.dueMileage,
            lastPerformed: lastPerformed,
            lastMileage: lastMileage
        )
    }

    /// Plans for the included items only, in list order.
    static func plans(for items: [StarterScheduleItem], currentMileage: Int, now: Date = .now) -> [Plan] {
        items.filter(\.isIncluded).map { plan(for: $0, currentMileage: currentMileage, now: now) }
    }
}
