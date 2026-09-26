//
//  MileageUpdateAction.swift
//  checkpoint
//
//  A reading the user states as their odometer now — the mileage sheet or
//  "update mileage" in Siri. Authoritative, corrections downward included, so
//  it records through `Vehicle.recordMileage` directly instead of
//  `MileageCommit`'s newest-and-higher gate (see MileageCommit, "What this is
//  not for"). The mileage reminder restarts from today.
//
//  Model mutation plus the mileage reminder only. Callers refresh the icon,
//  widget and Spotlight, which the app does for its selected vehicle and an
//  intent does for the vehicle it wrote.
//

import Foundation
import SwiftData

enum MileageUpdateAction {

    static func record(_ miles: Int, for vehicle: Vehicle, in context: ModelContext, now: Date = .now) {
        vehicle.recordMileage(miles, recordedAt: now, source: .manual, in: context)
        NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: now)
    }
}
