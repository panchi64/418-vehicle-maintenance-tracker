//
//  StarterScheduleWriter.swift
//  checkpoint
//
//  Putting the starter schedule on a new vehicle: one recurring service per
//  plan (`StarterSchedule`, which stays pure), then the reminders, icon and
//  widget that follow. Shared by the sheet offered after Add Vehicle and by
//  Siri's Add Vehicle, so a schedule accepted by voice is the one the sheet
//  would have written.
//

import Foundation
import SwiftData

enum StarterScheduleWriter {

    /// Insert a service for each plan on `vehicle` and refresh what derives
    /// from its schedule. Returns the services, in plan order.
    @discardableResult
    static func insert(_ plans: [StarterSchedule.Plan], on vehicle: Vehicle, in context: ModelContext) -> [Service] {
        let services = plans.map { plan in
            let service = Service(
                name: plan.name,
                dueDate: plan.dueDate,
                dueMileage: plan.dueMileage,
                lastPerformed: plan.lastPerformed,
                lastMileage: plan.lastMileage,
                intervalMonths: plan.intervalMonths,
                intervalMiles: plan.intervalMiles,
                isRecurring: true
            )
            service.vehicle = vehicle
            context.insert(service)
            return service
        }
        DerivedSurfaces.refresh(for: vehicle)
        return services
    }

    /// The whole default list — every common service the vehicle doesn't
    /// already track, counted from today and the reading on file ("don't
    /// know" when each was last done). What accepting the sheet unchanged
    /// writes.
    static func defaultPlans(for vehicle: Vehicle, now: Date = .now) -> [StarterSchedule.Plan] {
        StarterSchedule.plans(for: offeredItems(for: vehicle), currentMileage: vehicle.currentMileage, now: now)
    }

    /// The starter list for `vehicle`: the common presets it doesn't track yet.
    static func offeredItems(for vehicle: Vehicle) -> [StarterScheduleItem] {
        StarterSchedule.items(
            from: PresetDataService.shared.loadPresets(),
            excluding: (vehicle.services ?? []).map(\.name)
        )
    }
}
