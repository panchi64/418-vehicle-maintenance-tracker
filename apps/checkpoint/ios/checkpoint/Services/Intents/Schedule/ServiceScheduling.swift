//
//  ServiceScheduling.swift
//  checkpoint
//
//  Putting a service on the schedule from Siri. The same projection the form
//  uses (`ReminderImpactCalculator.projected`, anchored at today and the
//  reading on file) turns a cadence into the first due date and mileage, and
//  an explicit due date or mileage wins over it.
//
//  Model mutation only; the intent commits.
//

import Foundation
import SwiftData

@MainActor
enum ServiceScheduling {

    /// What was said about when the service comes due. Mileage in stored miles.
    struct Request {
        var intervalMonths: Int?
        var intervalMiles: Int?
        var dueDate: Date?
        var dueMileage: Int?
    }

    enum Outcome {
        case added(Service)
        /// The vehicle already tracks a service by this name; adding another
        /// would count down twice.
        case alreadyScheduled(Service)
        /// Nothing said when it comes due, and no preset cadence to derive it.
        case needsDue
    }

    static func add(
        named name: String,
        to vehicle: Vehicle,
        request: Request,
        in context: ModelContext,
        now: Date = .now
    ) -> Outcome {
        if let existing = trackedService(named: name, on: vehicle) {
            return .alreadyScheduled(existing)
        }

        let preset = PresetDataService.shared.loadPresets().first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
        let intervalMonths = positive(request.intervalMonths) ?? preset?.defaultIntervalMonths
        let intervalMiles = positive(request.intervalMiles) ?? preset?.defaultIntervalMiles
        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            anchorDate: now,
            anchorMileage: vehicle.currentMileage,
            explicitDueDate: request.dueDate,
            explicitDueMileage: request.dueMileage
        )
        guard schedule.dueDate != nil || schedule.dueMileage != nil else { return .needsDue }

        let isRecurring = Service.hasIntervalPolicy(intervalMonths: intervalMonths, intervalMiles: intervalMiles)
        let service = Service(
            name: preset?.name ?? name,
            dueDate: schedule.dueDate,
            dueMileage: schedule.dueMileage,
            intervalMonths: isRecurring ? intervalMonths : nil,
            intervalMiles: isRecurring ? intervalMiles : nil,
            isRecurring: isRecurring
        )
        service.vehicle = vehicle
        context.insert(service)
        return .added(service)
    }

    /// The vehicle's service by this name that is still counting down.
    static func trackedService(named name: String, on vehicle: Vehicle) -> Service? {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (vehicle.services ?? []).first {
            $0.hasDueTracking && $0.name.caseInsensitiveCompare(needle) == .orderedSame
        }
    }

    private static func positive(_ value: Int?) -> Int? {
        value.flatMap { $0 > 0 ? $0 : nil }
    }
}
